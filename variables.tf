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

# locals {
#   location              = "East US"
#   vnet_cidr             = "10.0.0.0/8"
#   subnet_address_prefix = "10.240.0.0/24"
#   my_ip                 = "101.53.219.90/32"
#   worker_count          = 3
# }
