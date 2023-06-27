#!/bin/bash

client_ip="$(curl -s "https://checkip.amazonaws.com")"

terraform init -backend-config="key=uds-aws-ci-k3d/${ID}.tfstate"

terraform destroy -var="client_ip=$client_ip" --auto-approve
