#!/bin/bash

set -e

export DOCKER_VERSION="5:24.0.2-1~ubuntu.22.04~jammy"
export CONTAINERD_VERSION="1.6.21-1"
export K3D_VERSION="v5.5.1"

# Install docker
sudo apt-get update -y
sudo apt-get install ca-certificates curl gnupg -y

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
"deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get install -y \
    docker-ce="$DOCKER_VERSION" \
    docker-ce-cli="$DOCKER_VERSION" \
    containerd.io="$CONTAINERD_VERSION"

sudo usermod -aG docker ubuntu

# Install k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG="$K3D_VERSION" bash

# Install aws cli
sudo apt-get install unzip -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Remove transient dependencies
sudo apt-get purge -y \
    ca-certificates \
    curl \
    gnupg \
    unzip
