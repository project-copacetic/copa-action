#!/usr/bin/env bats
load_lib() {
  local name="$1"
  load "test_helper/${name}/load"
}

load_lib bats-support
load_lib bats-assert

setup() {
    docker run --detach --rm --privileged -p 127.0.0.1:8888:8888/tcp --name buildkitd --entrypoint buildkitd moby/buildkit:v0.12.0 --addr tcp://0.0.0.0:8888
    run ./entrypoint.sh 'mcr.microsoft.com/oss/nginx/nginx:1.21.6' 'nginx.1.21.6.json' '-patched'
}

teardown() {
    docker stop buildkitd
}

@test "Check patched docker image IDs" {
    run docker images --quiet mcr.microsoft.com/oss/nginx/nginx:1.21.6-patched
    id="$output"
    assert_equal "$id" "77a7630a38cf"
}

@test "Run trivy on patched image" {
    run trivy image --vuln-type os --ignore-unfixed -f json -o nginx.1.21.6-patched.json mcr.microsoft.com/oss/nginx/nginx:1.21.6-patched
    run diff "./data/patched-report.json" "nginx.1.21.6-patched.json"
    assert_equal "$output" ""
}
