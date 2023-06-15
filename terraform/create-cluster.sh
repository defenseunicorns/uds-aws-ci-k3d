#!/bin/bash

function checkError() {
    if [ $? -ne 0 ]
    then
        echo "Terraform exited with error"
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

terraform init -backend-config="key=uds-aws-ci-k3d/${SHA:0:7}.tfstate"
checkError

terraform plan -var="client_ip=$client_ip"
checkError

terraform apply -var="client_ip=$client_ip" --auto-approve
checkError

instance_id="$(terraform output -raw instance_id)"
secret_name="$(terraform output -raw secret_name)"

echo "instance_id=${instance_id}" >> $GITHUB_OUTPUT
echo "secret_name=${secret_name}" >> $GITHUB_OUTPUT

waitInstanceReady "$instance_id"

rm -rf ~/.kube/config

mkdir ~/.kube

aws secretsmanager get-secret-value \
    --secret-id "$secret_name" \
    --query 'SecretString' \
    --output text > ~/.kube/config

zarf tools kubectl get nodes -o wide

rm -rf .terraform
