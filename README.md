# Copacetic Action

[Marketplace](https://github.com/marketplace/actions/copacetic-action)

This action patches vulnerable containers using [Copa](https://github.com/project-copacetic/copacetic).
Copacetic Action is supported with Copa version 0.3.0 and later.

## Inputs

| Name               | Type   | Required | Default  | Description                                           |
| ------------------ | ------ | -------- | -------- | ----------------------------------------------------- |
| `image`            | String | True     |          | Image reference to patch                              |
| `image-report`     | String | True     |          | Trivy JSON vulnerability report of the image to patch |
| `patched-tag`      | String | True     |          | Patched image tag                                     |
| `timeout`          | String | False    | `5m`     | Timeout for `copa patch`                              |
| `buildkit-version` | String | False    | `latest` | Buildkit version                                      |
| `copa-version`     | String | False    | `latest` | Copa version                                          |

## Outputs

| Name            | Type   | Description                          |
| --------------- | ------ | ------------------------------------ |
| `patched-image` | String | Image reference of the patched image |

## Example usage

```yaml
on: [push]

jobs:
    test:
        runs-on: ubuntu-latest

        strategy:
          fail-fast: false
          matrix:
            # provide relevant list of images to scan on each run
            images:
              - "docker.io/library/nginx:1.21.6"
              - "docker.io/openpolicyagent/opa:0.46.0"
              - "docker.io/library/hello-world:latest"

        steps:
        - name: Generate Trivy Report
          uses: aquasecurity/trivy-action@d43c1f16c00cfd3978dde6c07f4bbcf9eb6993ca # 0.16.1
          with:
            scan-type: 'image'
            format: 'json'
            output: 'report.json'
            ignore-unfixed: true
            vuln-type: 'os'
            image-ref: ${{ matrix.images }}

        - name: Check Vuln Count
          id: vuln_count
          run: |
            report_file="report.json"
            vuln_count=$(jq '.Results | length' "$report_file")
            echo "vuln_count=$vuln_count" >> $GITHUB_OUTPUT

        - name: Copa Action
          if: steps.vuln_count.outputs.vuln_count != '0'
          id: copa
          uses: project-copacetic/copa-action@v1
          with:
            image: ${{ matrix.images }}
            image-report: 'report.json'
            patched-tag: 'patched'
            buildkit-version: 'v0.11.6' # optional, default is latest
            copa-version: '0.6.0' # optional, default is latest

        - name: Login to Docker Hub
          if: steps.copa.conclusion == 'success'
          id: login
          uses: docker/login-action@343f7c4344506bcbf9b4de18042ae17996df046d # v3.0.0
          with:
            username: 'user'
            password: ${{ secrets.DOCKERHUB_TOKEN }}

        - name: Docker Push Patched Image
          if: steps.login.conclusion == 'success'
          run: |
            docker push ${{ steps.copa.outputs.patched-image }}
```
