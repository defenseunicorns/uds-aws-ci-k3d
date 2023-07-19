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

variable "k3d_config" {
  type    = string
  default = "k3d-calico.yaml"
}