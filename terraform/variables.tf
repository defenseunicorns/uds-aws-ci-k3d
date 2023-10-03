variable "client_ip" {
  type    = string
  default = ""
}

variable "suffix" {
  type    = string
  default = ""
}

variable "instance_size" {
  type    = string
  default = "m5.4xlarge"
}

variable "ami_prefix" {
  type    = string
  default = "uds-ci-k3d"
}

variable "k3d_config" {
  type    = string
  default = "k3d-calico.yaml"
}

# variable "gpu" {
#  type    = string
#  default = "none"
# }

# variable "k3s_version" {
#  type    = string
#  default = "v1.26.6+k3s1"
# }