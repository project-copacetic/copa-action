#!/usr/bin/env bats

load helpers

teardown_file() {
    docker stop buildkitd
}

@test "Check patched image exists" {
    docker images
    id=$(docker images --quiet 'nginx:1.21.6-patched')
    assert_not_equal "$id" ""
}

@test "Check output.json exists" {
    run test -f /tmp/output.json
    [ "$status" -eq 0 ]
}

@test "Run trivy on patched image" {
    run trivy image --exit-code 1 --vuln-type os --ignore-unfixed -f json -o nginx.1.21.6-patched.json 'docker.io/library/nginx:1.21.6-patched'
    [ "$status" -eq 0 ]
    vulns=$(jq 'if .Results then [.Results[] | select(.Class=="os-pkgs" and .Vulnerabilities!=null) | .Vulnerabilities[]] | length else 0 end' nginx.1.21.6-patched.json)
    assert_equal "$vulns" "0"
}
