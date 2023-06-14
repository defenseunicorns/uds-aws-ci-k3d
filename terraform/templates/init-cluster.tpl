#!/bin/bash

public_ip="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"

# Create k3d cluster
k3d cluster create \
    --config k3d-config.yaml \
    --k3s-arg "--tls-san=$public_ip@server:*"

# Edit kubeconfig
k3d kubeconfig get ci > kubeconfig.yaml
kubeconfig=$(sed 's/0\.0\.0\.0/'"$public_ip"'/g' kubeconfig.yaml)

# Upload kubeconfig to secrets manager
aws secretsmanager put-secret-value \
    --secret-id "${secret_id}" \
    --secret-string "$(echo "$kubeconfig")"
