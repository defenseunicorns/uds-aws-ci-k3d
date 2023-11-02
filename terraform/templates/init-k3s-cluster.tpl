#!/bin/bash

public_ip="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"

export INSTALL_K3S_VERSION="v1.26.9+k3s1"

aws configure set region "${region}"

# Download aws controller plugin
mkdir -p /var/lib/rancher/k3s/server/manifests/
scp /calico.yaml /var/lib/rancher/k3s/server/manifests/

snap install helm --classic



curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - \
    --node-name="$(hostname).ec2.internal" \
    --disable=traefik \
    --disable=servicelb \
    --cluster-init \
    --write-kubeconfig-mode=644  \
    --flannel-backend=none \
    --disable-network-policy \
    --disable=metrics-server \
    --kubelet-arg="provider-id=aws:///$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)/$(curl -s http://169.254.169.254/latest/meta-data/instance-id)" \
    --kubelet-arg="cloud-provider=external" \
    --tls-san="$(hostname -s)" \
    --tls-san="$public_ip" \
    --disable-cloud-controller 

# is this needed?
#    --cluster-cidr=172.31.0.0/16 \
#    --service-cidr=192.168.0.0/16 \


# Update Path
echo 'export PATH=$PATH:/usr/local/bin/' |
    tee -a  ~root/.bashrc > /dev/null

# Wait for k3s
while [[ ! -f /etc/rancher/k3s/k3s.yaml ]]; do
    sleep 2
done

mkdir -p "$HOME/.kube/"
scp /etc/rancher/k3s/k3s.yaml "$HOME/.kube/config"

# Install Calico
echo "Waiting for Calico to be ready..."
kubectl wait --for=condition=Ready pods --all --all-namespaces 2>&1 >/dev/null

#install cloud controller manager
export KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
helm repo add aws-cloud-controller-manager https://kubernetes.github.io/cloud-provider-aws
helm repo update

cat <<EOF > values.yaml
args:
  - --v=2
  - --cloud-provider=aws
  - --configure-cloud-routes=false
nodeSelector:
  node-role.kubernetes.io/master: "true"
  node-role.kubernetes.io/control-plane: "true"
EOF



Error syncing load balancer: failed to ensure load balancer: error get availability zone types: "error describe availability zones: \"error listing AWS availability zones: \\\"UnauthorizedOperation: You are not authorized to perform this operation.\\\\n\\\\tstatus code: 403, request id: 257fa8db-99f2-475a-9c06-52f645680448\\\"\""

helm upgrade --install aws-cloud-controller-manager aws-cloud-controller-manager/aws-cloud-controller-manager \
--values values.yaml --kubeconfig "/etc/rancher/k3s/k3s.yaml"

# Edit kubeconfig
kubeconfig=$(sed -E 's/(0\.0\.0\.0|127\.0\.0\.1)/'"$public_ip"'/g' "$HOME/.kube/config")
# Upload kubeconfig to secrets manager
aws secretsmanager put-secret-value \
    --secret-id "${secret_id}" \
    --secret-string "$(echo "$kubeconfig")"
