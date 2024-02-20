# Copacetic Action

[Marketplace](https://github.com/marketplace/actions/copacetic-action)

This action patches vulnerable containers using [Copa](https://github.com/project-copacetic/copacetic).
Copacetic Action is supported with Copa version 0.3.0 and later.

## Inputs

| Name               | Type   | Required | Default   | Description                                                                           |
| ------------------ | ------ | -------- | --------- | ------------------------------------------------------------------------------------- |
| `image`            | String | True     |           | Image reference to patch                                                              |
| `image-report`     | String | True     |           | Trivy JSON vulnerability report of the image to patch                                 |
| `patched-tag`      | String | True     |           | Patched image tag                                                                     |
| `timeout`          | String | False    | `5m`      | Timeout for `copa patch`                                                              |
| `buildkit-version` | String | False    | `latest`  | Buildkit version                                                                      |
| `copa-version`     | String | False    | `latest`  | Copa version                                                                          |
| `output`           | String | False    |           | Output filename (available using copa-action with copa v0.6.1 and later)              |
| `format`           | String | False    | `openvex` | Output format (available using copa-action with copa v0.6.1 and later)                |
| `custom-socket`    | String | False    |           | Custom Docker socket address (available using copa-action with copa v0.6.1 and later) | 

> [!NOTE] 
> Features that are supported with new Copacetic releases will not neccessarily align with what is supported with Copa Action. 
> For example, the `output` file feature was released in Copa v0.5.0, but is supported with Copa Action when using Copa version v0.6.1 and later.

## Outputs

| Name            | Type   | Description                          |
| --------------- | ------ | ------------------------------------ |
| `patched-image` | String | Image reference of the patched image |

## Ways to connect to Buildkit
> [!NOTE] 
Custom Buildkit connection to patch local or private images is only available with Copa-Action versions 0.6.1 and later. For all earlier Copa-Action versions, Buildkit in a container is the default approach, and a version must be supplied as input.

### Option 1: Connect to buildx instance (default)
By default, Copa Action creates its own Buildx instance to connect to for patching public and private images.

### Option 2: Connect using defaults through a custom socket
To patch local images, `copa` is limited to using `docker`'s built-in buildkit service, and must use the [`containerd image store`](https://docs.docker.com/storage/containerd/) feature. To enable this in your Github workflow, use `ghaction-setup-docker`'s [daemon-configuration](https://github.com/crazy-max/ghaction-setup-docker#daemon-configuration) to set `"containerd-snapshotter": true`.

Example:
``` yaml
    - name: Set up Docker
        uses: crazy-max/ghaction-setup-docker@v3
        with:
        daemon-config: |
            {
            "debug": true,
            "experimental": true,
                "features": {
                "containerd-snapshotter": true
                }
            }
    - name: Get socket path
        run: |
            url=$(docker context inspect | jq -r .[0].Endpoints.docker.Host)
            socket_path=$(echo "$url" | awk -F// '{print $2}')
            echo "$socket_path"
            echo "SOCKET=$socket_path" >> $GITHUB_ENV
```

Then, supply the resulting socket path (`$SOCKET`) as the input `custom-socket` for the Copa Action to connect to.
> [!NOTE] 
> Copa Action will load the image to the default docker context, not the "setup-docker-action" context.

### Option 3: Buildkit in a container
To connect via buildkit in a container, provide the input `buildkit-version`. Copa Action will create a buildkit container with that version to connect to. 
> [!NOTE]
> This approach does not allow for patching of local or private images.


Refer to [Copacetic documentation](https://project-copacetic.github.io/copacetic/website/custom-address) to learn more about connecting Copa to Buildkit.

## Example usage

https://github.com/project-copacetic/copa-action/blob/941743581b0da5e581ca5a575f9316228c2f6c00/.github/workflows/patch.yaml#L1-L77
