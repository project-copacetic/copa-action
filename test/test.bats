#!/usr/bin/env bats

load helpers

setup() {
    docker run --detach --rm --privileged -p 127.0.0.1:8888:8888/tcp --name buildkitd --entrypoint buildkitd moby/buildkit:v0.12.0 --addr tcp://0.0.0.0:8888
}

teardown() {
    docker stop buildkitd
}

@test "Check patched docker image IDs" {
    run ../entrypoint.sh 'docker.io/library/nginx:1.21.6' 'nginx.1.21.6.json' '1.21.6-patched'
    run docker images --quiet 'nginx:1.21.6-patched'
    id="$output"
    assert_equal "$id" "4319b9b0e0c2"
}

@test "Run trivy on patched image" {
    run ../entrypoint.sh 'docker.io/library/nginx:1.21.6' 'nginx.1.21.6.json' '1.21.6-patched'
    run trivy image --vuln-type os --ignore-unfixed -f json -o nginx.1.21.6-patched.json 'docker.io/library/nginx:1.21.6-patched'
    run diff "./data/patched-report.json" "nginx.1.21.6-patched.json"
    assert_equal "$output" ""
}
