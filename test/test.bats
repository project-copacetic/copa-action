#!/usr/bin/env bats

load helpers

setup_file(){
    docker run --net=host --detach --rm --privileged -p 127.0.0.1:8888:8888 --name buildkitd --entrypoint buildkitd moby/buildkit:v0.12.0 --addr tcp://0.0.0.0:8888
}

teardown_file(){
    docker ps -a
    docker stop buildkitd
}

@test "Run copa in container" {
    run docker run --net=host \
        --mount=type=bind,source=$(pwd)/data,target=/data \
        --mount=type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
        --mount=type=bind,source=$GITHUB_OUTPUT,target=$GITHUB_OUTPUT -e GITHUB_OUTPUT \
        --name=copa-action \
        copa-action 'docker.io/library/nginx:1.21.6' 'nginx.1.21.6.json' '1.21.6-patched'
    assert_success
}

@test "Check patched docker image IDs" {
    id=$(docker images --quiet 'nginx:1.21.6-patched')
    assert_equal "$id" "4319b9b0e0c2"
}

@test "Run trivy on patched image" {
    run trivy image --vuln-type os --ignore-unfixed -f json -o nginx.1.21.6-patched.json 'docker.io/library/nginx:1.21.6-patched'
    diff=$(diff "./data/patched-report.json" "nginx.1.21.6-patched.json")
    assert_equal "$diff" ""
}
