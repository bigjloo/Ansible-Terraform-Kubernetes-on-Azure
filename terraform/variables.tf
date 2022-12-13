variable "resource_group_location" {
  type        = string
  description = "Resource Group Location"
  default     = "East US"
}

variable "vnet_CIDR" {
  type        = string
  description = "CIDR for virtual network"
  default     = "10.0.0.0/8"
}

variable "subnet_address_prefix" {
  type        = string
  description = "subnet address prefix"
}

variable "my_ip" {
  type        = string
  description = "IP for admin"
}

variable "worker_count" {
  type        = number
  description = "Number of worker nodes"
  default     = 2
}

variable "admin_username" {
  type        = string
  description = "username for vm root"
  default     = "kuberoot"
}

variable "path_to_ssh_pub_key" {
  type        = string
  description = "path to admin ssh public key"
  default     = "~/.ssh/id_rsa.pub"
}
