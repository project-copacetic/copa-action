#!/usr/bin/env bats

load helpers

teardown_file(){
    docker ps -a
    docker stop buildkitd
}

@test "Check patched image exists" {
    docker images
    id=$(docker images --quiet 'nginx:1.21.6-patched')
    assert_not_equal "$id" ""
}

@test "Run trivy on patched image" {
    trivy image --vuln-type os --ignore-unfixed -f json -o nginx.1.21.6-patched.json 'docker.io/library/nginx:1.21.6-patched'
    vulns=$(jq '.Results[0].Vulnerabilities | length' nginx.1.21.6-patched.json)
    assert_equal "$vulns" "0"
}
