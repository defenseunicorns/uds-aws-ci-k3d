#!/bin/bash

public_ip="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"

export INSTALL_K3S_VERSION="v1.26.5-k3s1"

if [[ ${node_type} == "server" ]]; then

    # Download aws controller plugin
    curl -sfL h https://raw.githubusercontent.com/kmcgrath/k3s-terraform-modules/master/manifests/cloud-provider-aws.yaml > cloud-provider-aws.yaml
    mkdir -p /var/lib/rancher/k3s/server/manifests/
    cp cloud-provider-aws.yaml /var/lib/rancher/k3s/server/manifests/
fi


curl -sfL https://get.k3s.io | sh -s - server \
    --node-name="$(hostname).ec2.internal" \
    --disable=traefik \
    --disable=servicelb \
    --cluster-init \
    --write-kubeconfig-mode=644  \
    --flannel-backend=none \
    --disable-network-policy \
    --disable=metrics-server \
    --kubelet-arg="provider-id=aws:///$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)/$(curl -s http://169.254.169.254/latest/meta-data/instance-id)" \
    --tls-san="$(hostname -s)" \
    --tls-san="$public_ip" \
    --disable-cloud-controller 



# Update Path
echo 'export PATH=$PATH:/usr/local/bin/' |
    sudo tee -a  ~root/.bashrc > /dev/null

# Wait for k3s
while [[ ! -f /etc/rancher/k3s/k3s.yaml ]]; do
    sleep 2
done

mkdir -p "$HOME/.kube/"
scp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"

# Install Calico
echo "Installing Calico..."
kubectl apply --wait=true -f calico.yaml 2>&1 >/dev/null
echo "Waiting for Calico to be ready..."
kubectl rollout status deployment/calico-kube-controllers -n kube-system --watch --timeout=90s 2>&1 >/dev/null
kubectl rollout status daemonset/calico-node -n kube-system --watch --timeout=90s 2>&1 >/dev/null
kubectl wait --for=condition=Ready pods --all --all-namespaces 2>&1 >/dev/null


# Edit kubeconfig
kubeconfig=$(sed 's/0\.0\.0\.0/'"$public_ip"'/g' $HOME/.kube/config)
# Upload kubeconfig to secrets manager
aws secretsmanager put-secret-value \
    --secret-id "${secret_id}" \
    --secret-string "$(echo "$kubeconfig")"
