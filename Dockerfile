FROM ubuntu:23.04

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

# Copy all trivy report data
COPY *.json /data/

# Mount data volume
VOLUME /data

# Install required packages
RUN apt-get update && \
    apt-get install -y wget tar runc sudo systemd apt-transport-https ca-certificates gnupg lsb-release --no-install-recommends

# Install Copa
RUN wget -q https://github.com/project-copacetic/copacetic/releases/download/v0.2.0/copa_0.2.0_linux_amd64.tar.gz && \
    tar -zxvf copa_0.2.0_linux_amd64.tar.gz && \
    cp copa /usr/local/bin/

# Install Docker
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN wget -qO- https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io --no-install-recommends

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
