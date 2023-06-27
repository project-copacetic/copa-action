FROM debian:12-slim

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

# Copy all trivy report data
COPY *.json /data/

# Mount data volume
VOLUME /data

# Install required packages
RUN apt-get update && \
    apt-get install -y wget tar sudo ca-certificates gnupg curl --no-install-recommends && \
    # Import Docker GPG key
    sudo install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    sudo chmod a+r /etc/apt/keyrings/docker.gpg && \
    # Add the Docker repository with the correct key ID
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    # Install Docker
    apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io --no-install-recommends

# Install Copa
RUN wget -q https://github.com/project-copacetic/copacetic/releases/download/v0.2.0/copa_0.2.0_linux_amd64.tar.gz && \
    tar -zxvf copa_0.2.0_linux_amd64.tar.gz && \
    cp copa /usr/local/bin/

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
