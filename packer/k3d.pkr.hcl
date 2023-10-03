packer {
  required_version = ">= 1.8.7"

  required_plugins {
    amazon = {
      version = ">= 1.1.6"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  ami_name = "${var.ami_name}-${formatdate("YYYYMMDDhhmm", timestamp())}"
}

source "amazon-ebs" "ubuntu" {
  ami_name        = local.ami_name
  ami_description = "For testing UDS in a pipeline"
  instance_type   = "t3a.medium"
  region          = "us-west-2"
  ssh_username    = "ubuntu"
  # ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20230608
  source_ami = "ami-022c9f1a24f813bf9"
}

build {
  name    = local.ami_name
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    script  = "./limits.sh"
    timeout = "1m"
  }

  provisioner "file" {
    source      = "k3d-config.yaml"
    destination = "/tmp/k3d-config.yaml"
  }

  provisioner "shell" {
    inline = ["sudo mv /tmp/k3d-config.yaml /k3d-config.yaml"]
  }

  provisioner "shell" {
    script  = "./install-tools.sh"
    timeout = "15m"
  }
}
