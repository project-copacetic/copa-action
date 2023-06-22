#!/bin/sh

image=$1
report=$2
patched_tag=$3

# parse image into image name and image tag
image_no_tag=$(echo "$image" | cut -d':' -f1)
old_tag=$(echo "$image" | cut -d':' -f2)

# new patched image tag
new_tag="$old_tag$patched_tag"

# run copa to patch image
if copa patch -i "$image" -r /data/"$report" -t "$new_tag" --addr tcp://0.0.0.0:8888;
then
    patched_image="$image_no_tag:$new_tag"
    # echo "::set-output name=patched-image::$patched_image"
    echo "patched-image=$patched_image" >> $GITHUB_OUTPUT
else
    echo "Error patching image $image with copa"
    exit 1
fi
