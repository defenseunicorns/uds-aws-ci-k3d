# uds-aws-ci-k3d

This repository contains code for the infrastructure to be used to spin up ephemeral k3d clusters in AWS for DUBBD CI.

## Amazon Machine Image (AMI)

- The code for the AMI is in the `packer/` directory

- An AMI is built and pushed to the CI AWS account in the `.github/workflows/ami-build.yml` workflow

- The AMI is rebuilt nightly to ensure the tools and dependencies stay updated

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


