#!/bin/bash

client_ip="$(curl -s "https://checkip.amazonaws.com")"

terraform init -backend-config="key=uds-aws-ci-k3d/${ID}.tfstate"

terraform destroy -var="client_ip=$client_ip" -var="suffix=${ID}" \
    -var="instance_size=${INSTANCE_SIZE}" -var="k3d_config=${K3D_CONFIG}" \
     -var="ami_prefix=${AMI_PREFIX}" -var="k3s=${K3S}" --auto-approve

rm -rf .terraform