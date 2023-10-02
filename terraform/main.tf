provider "aws" {
  region = "us-west-2"
}

resource "random_id" "unique_id" {
  byte_length = 4
}

data "aws_ami" "latest_ubuntu_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["uds-ci-k3d-*"]
  }

  owners = ["248783118822"]
}

locals {
  init_cluster_template = templatefile("${path.module}/templates/init-cluster.tpl",
    {
      secret_id = aws_secretsmanager_secret.kubeconfig.name
      k3d_config_file = var.k3d_config
  })
  suffix = var.suffix != "" ? "${var.suffix}-${random_id.unique_id.hex}" : random_id.unique_id.hex

  tags = tomap({
      "Name"         = "uds-ci-k3d-${local.suffix}"
      "ManagedBy"    = "Terraform"
      "CreationDate" = time_static.creation_time.rfc3339
  })
}

resource "time_static" "creation_time" {}

resource "aws_instance" "ec2_instance" {
  ami                    = data.aws_ami.latest_ubuntu_ami.image_id
  instance_type          = "m5.4xlarge"                                   # vCPU: 16 -- RAM: 64GB
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.name # Instance profile to allow us to upload kubeconfig to secrets manager
  vpc_security_group_ids = [aws_security_group.security_group.id]
  user_data              = local.init_cluster_template

  root_block_device {
    volume_size           = 250
    volume_type           = "gp2"
    delete_on_termination = true
  }

  tags = local.tags
}

resource "aws_security_group" "security_group" {
  name        = "kube-api-access-${random_id.unique_id.hex}"
  description = "Allow Kube API access only from GitHub runner"

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["${var.client_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.tags
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "upload_kubeconfig-${random_id.unique_id.hex}"
  role = aws_iam_role.instance_role.name
  tags = local.tags
}

resource "aws_iam_role" "instance_role" {
  name = "upload_kubeconfig-${random_id.unique_id.hex}"
  permissions_boundary = "arn:aws:iam::248783118822:policy/unicorn-base-policy"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  tags = local.tags
}

resource "aws_iam_policy" "secrets_manager_policy" {
  name        = "upload_kubeconfig_policy-${random_id.unique_id.hex}"
  description = "Allows creating secrets in secrets manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "secretsmanager:*"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_manager" {
  role       = aws_iam_role.instance_role.name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}

resource "aws_secretsmanager_secret" "kubeconfig" {
  name        = "uds-ci-k3d-${random_id.unique_id.hex}/k3d-kubeconfig"
  description = "UDS CI k3d kubeconfig"
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "kubeconfig" {
  secret_id     = aws_secretsmanager_secret.kubeconfig.id
  secret_string = "placeholder"
}
