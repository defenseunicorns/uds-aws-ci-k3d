#!/bin/bash

public_ip="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"

cat <<EOF > zarf-config.yaml
log-level: info
architecture: amd64
package:
  create: 
    max_package_size: 1000000000
    set:
      k3d_cluster_name: dubbd
      tls-san: $public_ip
      gpu: ${gpu}
      cni: ${cni}
      k3s_version: ${k3s_version}
EOF

# # Create k3d cluster
# k3d cluster create \
#     --config ${k3d_config} \
#     --k3s-arg "--tls-san=$public_ip@server:*"

# Edit kubeconfig
k3d kubeconfig get ci > kubeconfig.yaml
kubeconfig=$(sed 's/0\.0\.0\.0/'"$public_ip"'/g' kubeconfig.yaml)

# Upload kubeconfig to secrets manager
aws secretsmanager put-secret-value \
    --secret-id "${secret_id}" \
    --secret-string "$(echo "$kubeconfig")"
