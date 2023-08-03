FROM debian:12-slim

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Get copa_version arg
ARG copa_version

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh 

# Install required packages
RUN apt-get update && \
    apt-get install -y tar ca-certificates gnupg curl jq --no-install-recommends && \
    # Import Docker GPG key
    install -m 0755 -d /etc/apt/keyrings && \
    curl --retry 5 -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    # Add the Docker repository with the correct key ID
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    # Install Docker
    apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io --no-install-recommends

# Install Copa
RUN curl --retry 5 -fsSL -o copa.tar.gz https://github.com/project-copacetic/copacetic/releases/download/v${copa_version}/copa_${copa_version}_linux_amd64.tar.gz && \
    tar -zxvf copa.tar.gz && \
    cp copa /usr/local/bin/

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
