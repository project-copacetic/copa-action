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
| `format`           | String | False    | `openvex` | Output format                                        |
| `output`           | String | False    |          | Output filename                                       |

## Outputs

| Name            | Type   | Description                          |
| --------------- | ------ | ------------------------------------ |
| `patched-image` | String | Image reference of the patched image |

## Example usage

https://github.com/project-copacetic/copa-action/blob/941743581b0da5e581ca5a575f9316228c2f6c00/.github/workflows/patch.yaml#L1-L77