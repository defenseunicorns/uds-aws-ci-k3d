#!/bin/bash

set -e

# renovate: datasource=github-tags depName=k3d-io/k3d versioning=semver
export K3D_VERSION="v5.5.1"

# renovate: datasource=github-tags depName=aws/aws-cli versioning=semver
export AWS_CLI_VERSION="2.12.0"

# Install docker
sudo apt-get update -y
sudo apt-get -y install ca-certificates curl gnupg

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
"deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce containerd.io

sudo usermod -aG docker ubuntu

# Install k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG="$K3D_VERSION" bash

# Install aws cli
sudo apt-get -y install unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# unzip is only needed to install aws cli, so we can uninstall
apt-get purge -y unzip
