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

#variable "k3d_config" {
#  type    = string
#  default = "k3d-calico.yaml"
#}

variable "cni" {
  type    = string
  default = "calico"
}

variable "gpu" {
  type    = string
  default = "none"
}

variable "k3s_version" {
  type    = string
  default = "v1.26.6+k3s1"
}