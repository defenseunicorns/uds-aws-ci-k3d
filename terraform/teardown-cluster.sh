#!/bin/bash

client_ip="$(curl -s "https://checkip.amazonaws.com")"

terraform init -backend-config="key=uds-aws-ci-k3d/${ID}.tfstate"

terraform destroy -var="client_ip=$client_ip" -var="suffix=${ID}" \
    -var="instance_size=${INSTANCE_SIZE}" -var="cni=${CNI}" \
    -var="gpu=${GPU} -var="k3s_version="${K3S_VERSION}" \
    --auto-approve
