#!/bin/bash

function checkError() {
    if [ $? -ne 0 ]
    then
        echo "$1 exited with error"
        exit 1
    fi
}

function waitInstanceReady() {
    timeout="$(( $(date +%s) + 600 ))"  # Set the timeout to 10 minutes (600 seconds)
    while true
    do
        echo "Waiting for EC2 instance to be ready"
        instance_state="$(aws ec2 describe-instances --instance-ids "$1" --query "Reservations[].Instances[].State.Name" --output text)"

        if [[ $instance_state == "running" ]]
        then
            instance_status="$(aws ec2 describe-instance-status --instance-ids "$1" --query "InstanceStatuses[].InstanceStatus[].Status" --output text)"

            if [[ $instance_status == "ok" ]]
            then
                echo "Instance is ready!"
                break
            fi
        fi

        current_time="$(date +%s)"
        if (( current_time >= timeout ))
        then
            echo "Timed out waiting for EC2 instance to be ready"
            exit 1
        fi

        sleep 5
    done
}

client_ip="$(curl -s "https://checkip.amazonaws.com")"

terraform init -backend-config="key=uds-aws-ci-k3d/${ID}.tfstate"
checkError "terraform"


terraform plan -var="client_ip=$client_ip" -var="suffix=${ID}" \
    -var="instance_size=${INSTANCE_SIZE}" -var="k3d_config=${K3D_CONFIG}" \
    -var="ami_prefix=${AMI_PREFIX}" -var="k3s=${K3S}"

checkError "terraform"

terraform apply -var="client_ip=$client_ip" -var="suffix=${ID}" \
    -var="instance_size=${INSTANCE_SIZE}" -var="k3d_config=${K3D_CONFIG}" \
    -var="ami_prefix=${AMI_PREFIX}" -var="k3s=${K3S}" --auto-approve

checkError "terraform"

instance_id="$(terraform output -raw instance_id)"
secret_name="$(terraform output -raw secret_name)"

echo "instance-id=${instance_id}" >> "$GITHUB_OUTPUT"
echo "secret-name=${secret_name}" >> "$GITHUB_OUTPUT"

waitInstanceReady "$instance_id"

rm -rf ~/.kube/config

mkdir ~/.kube

aws secretsmanager get-secret-value \
    --secret-id "$secret_name" \
    --query 'SecretString' \
    --output text > ~/.kube/config

#zarf tools kubectl get nodes -o wide
#checkError "zarf"

rm -rf .terraform
