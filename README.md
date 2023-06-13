# Copa Action

This action patches vulnerable containers using [Copa](https://github.com/project-copacetic/copacetic).

## Inputs

## `image`

**Required** The image reference to patch.

## `image-report`

**Required** The trivy json vulnerability report of the image to patch.

## `patched-tag`

**Required** The patched image tag to append to the original tag.

## Output

## `patched-image`

Image reference of the resulting patched image.

## Example usage

```
on: [push]

jobs:
    test:
        runs-on: ubuntu-latest

        strategy:
          fail-fast: false
          matrix:
            # provide relevant list of images to scan on each run
            images: ['docker.io/user/nginx:1.21.6', 'docker.io/user/opa:0.46.0', 'docker.io/user/hello-world:latest']

        steps:
        - name: Checkout repository
          uses: actions/checkout@v2

        - name: Set up Docker Buildx
          uses: docker/setup-buildx-action@v2

        - name: Generate Trivy Report
          uses: aquasecurity/trivy-action@master
          with:
            scan-type: 'image'
            format: 'json'
            output: 'report.json'
            ignore-unfixed: true
            vuln-type: 'os'
            image-ref: ${{ matrix.images }}

        - name: Check Vuln Count
          id: vuln_cout
          run: |
            report_file="report.json"
            vuln_count=$(jq '.Results | length' "$report_file")
            echo "::set-output name=vuln_count::$vuln_count"

        - name: Copa Action
          if: steps.vuln_cout.outputs.vuln_count != '0'
          id: copa
          uses: copacetic/copa-action@v0.1.0
          with:
            image: ${{ matrix.images }}
            image-report: 'report.json'
            patched-tag: '-patched'

        - name: Login to Docker Hub
          if: steps.copa.conclusion == 'success'
          id: login
          uses: docker/login-action@v2
          with:
            username: 'user'
            password: ${{ secrets.DOCKERHUB_TOKEN }}

        - name: Docker Push Patched Image
          if: steps.login.conclusion == 'success'
          run: |
            docker push ${{ steps.copa.outputs.patched-image }}

```
