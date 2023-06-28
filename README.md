# uds-aws-ci-k3d

This repository contains code for the infrastructure used to spin up ephemeral k3d clusters in AWS for DUBBD CI.

## Amazon Machine Image (AMI)

- The code for the AMI is in the `packer/` directory

- An AMI is built and pushed to the CI AWS account in the `.github/workflows/test-k3d-infra.yml` workflow

- The AMI is using Ubuntu 22.04 as the base OS, and has the following tools installed:
  - docker
  - k3d
  - aws cli

## AWS infrastructure

- The code for the AWS infrastructure is in the `terraform/` directory

- The following resources are created:
  - EC2 instance for the k3d cluster to run on

  - Security group to allow ingress on port `6443` to the Kubernetes API. Access is only allowed from the IP address of the client that created the infrastructure, which in this case would be a GitHub runner. Egress is unrestricted.

  - A Secrets Manager secret is created to store the kubeconfig

  - An instance profile with an associated IAM role and policy is attached to the EC2 instance to provide it the necessary permissions to upload the kubeconfig to Secrets Manager.

## Overview

1. A pipeline is triggered by a git commit

1. An EC2 instance and Secrets Manager secret are created

1. On launch, a k3d cluster is created on the EC2 instance using a [user data script](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts). Once the k3d cluster has created successfully, the user data script then uploads the kubeconfig as a secret in Secrets Manager.

1. Once the EC2 instance reaches a `running` state, the kubeconfig is then downloaded from Secrets Manager to the GitHub runner at `~/.kube/config`.

1. Zarf can now connect to the cluster using the kubeconfig at `~/.kube/config`

1. Initialize the cluster with Zarf

1. Deploy DUBBD to the cluster with Zarf

1. Teardown the cluster

## Usage

***Note***: This action is built to use AWS infrastructure in the Defense Unicorns CI account. It uses an existing S3 bucket and DynamoDB table for state storage and state locking.

To use this action in your repository, reach out to @lucasrod16 or @zachariahmiller to setup your repo with permissions to assume the IAM role. You will need the ARN of the IAM role used to authenticate to AWS stored as a GitHub Actions secret in your repository. See the examples below for how to use the `aws-assume-role` input to specify the IAM role ARN as a GitHub Actions secret.

### Create and destroy a k3d cluster in AWS

***Note***: If you are using this action in multiple, parallel jobs running on the same git commit, please reference the `Create and destroy a k3d cluster in AWS in parallel jobs` section below.

```yaml
- name: Create k3d cluster
   id: create-cluster
   uses: defenseunicorns/uds-aws-ci-k3d@v0.0.3
   with:
     cluster-action: create
     aws-assume-role: ${{ secrets.AWS_COMMERCIAL_ROLE_TO_ASSUME }}
     aws-region: us-west-2

# Deploy and run tests

- name: Teardown k3d cluster
  if: always()
  uses: defenseunicorns/uds-aws-ci-k3d@v0.0.3
  with:
    cluster-action: destroy
```


### Create and destroy a k3d cluster in AWS in parallel jobs

***Note***: This example uses a `unique-id` for cases when this action is used to spin up k3d clusters in parallel jobs triggered by the same git commit.

```yaml
- name: Generate unique id
  id: unique-id
  run: echo "unique-id=$(openssl rand -hex 8)" >> $GITHUB_OUTPUT

- name: Create k3d cluster
   id: create-cluster
   uses: defenseunicorns/uds-aws-ci-k3d@v0.0.3
   with:
     cluster-action: create
     aws-assume-role: ${{ secrets.AWS_COMMERCIAL_ROLE_TO_ASSUME }}
     aws-region: us-west-2
     unique-id: ${{ steps.unique-id.outputs.unique-id }}

# Deploy and run tests

- name: Teardown k3d cluster
  if: always()
  uses: defenseunicorns/uds-aws-ci-k3d@v0.0.3
  with:
    cluster-action: destroy
    unique-id: ${{ steps.unique-id.outputs.unique-id }}
```
