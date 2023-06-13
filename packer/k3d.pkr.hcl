packer {
  required_version = ">= 1.9.1"

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

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      architecture        = "x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
}

build {
  name    = local.ami_name
  sources = ["source.amazon-ebs.ubuntu"]

  provisioner "shell" {
    script  = "./install-tools.sh"
    timeout = "15m"
  }
}
