variable "tenancy_ocid" {
  type      = string
  sensitive = true
}

variable "user_ocid" {
  type      = string
  sensitive = true
}

variable "fingerprint" {
  type      = string
  sensitive = true
}

variable "private_key" {
  type      = string
  sensitive = true
}

variable "region" {
  type    = string
  default = "us-sanjose-1"
}

variable "compartment_ocid" {
  type = string
}

variable "ssh_public_key" {
  type      = string
  sensitive = true
}

variable "ssh_source_cidr" {
  type        = string
  description = "Temporary SSH source CIDR used only for provisioning."
}

variable "instance_name" {
  type    = string
  default = "abn-vpn-us-west-01"
}

variable "shape" {
  type    = string
  default = "VM.Standard.A1.Flex"
}

variable "ocpus" {
  type    = number
  default = 1
}

variable "memory_gbs" {
  type    = number
  default = 6
}

variable "wireguard_port" {
  type    = number
  default = 51820
}

variable "vcn_cidr" {
  type    = string
  default = "10.70.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "10.70.10.0/24"
}
