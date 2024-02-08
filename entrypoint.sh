#!/bin/sh 

set -ex;

image=$1
report=$2
patched_tag=$3
timeout=$4
output_file=$5
format=$6
connection_format=$7


# parse image into image name
image_no_tag=$(echo "$image" | cut -d':' -f1)

# check if output_file has been set
if [ -z "$output_file" ]
then
    output=""
else
    output="--format $format --output ./data/"$output_file""
fi

# check selected method of connection
case "$connection_format" in
    # through a buildx instance (allows for patching private images)
    "buildx")
        docker buildx create --name=copa-action
        docker buildx use --default copa-action
        connection="--addr buildx://copa-action"
        ;;
    # through a running buildkit container
    "buildkit-container")
        connection="--addr tcp://127.0.0.1:8888"
        ;;
    # none specified = through default docker buildkit endpoint (allows for patching local and private images)
    *)
        connection=""
        ;;
esac

# run copa to patch image
if copa patch -i "$image" -r ./data/"$report" -t "$patched_tag" $connection --timeout $timeout $output;
then
    patched_image="$image_no_tag:$patched_tag"
    echo "patched-image=$patched_image" >> "$GITHUB_OUTPUT"
else
    echo "Error patching image $image with copa"
    exit 1
fi
