#!/usr/bin/env bats

load helpers

teardown() {
    sudo docker stop buildkitd
}

@test "Run copa on docker.io/library/nginx:1.21.6" {
    docker run --detach --rm --network host --name buildkitd --entrypoint buildkitd moby/buildkit:v0.12.0 --addr 'tcp://0.0.0.0:8888'
    run ../entrypoint.sh 'docker.io/library/nginx:1.21.6' 'nginx.1.21.6.json' '1.21.6-patched'
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
