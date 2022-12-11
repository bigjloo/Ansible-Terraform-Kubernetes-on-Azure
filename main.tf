# locals {
#   location              = "East US"
#   vnet_cidr             = "10.0.0.0/8"
#   subnet_address_prefix = "10.240.0.0/24"
#   my_ip                 = "101.53.219.90/32"
#   worker_count          = 3
# }

resource "azurerm_resource_group" "kubernetes_terraform" {
  name     = "kubernetes-terraform"
  location = var.resource_group_location
}

resource "azurerm_network_security_group" "kubernetes_nsg" {
  name                = "kubernetes-nsg"
  location            = azurerm_resource_group.kubernetes_terraform.location
  resource_group_name = azurerm_resource_group.kubernetes_terraform.name

  security_rule {
    name                       = "allow-ssh"
    access                     = "Allow"
    destination_address_prefix = "*"
    destination_port_range     = 22
    direction                  = "Inbound"
    protocol                   = "Tcp"
    source_address_prefix      = var.my_ip
    source_port_range          = 22
    priority                   = 1000
  }

  security_rule {
    name                       = "allow-api-server"
    access                     = "Allow"
    destination_address_prefix = "*"
    destination_port_range     = 6443
    direction                  = "Inbound"
    protocol                   = "Tcp"
    source_address_prefix      = "*"
    source_port_range          = "*"
    priority                   = 1001
  }
}

resource "azurerm_virtual_network" "vnet_main" {
  name                = "vnet-main"
  location            = azurerm_resource_group.kubernetes_terraform.location
  resource_group_name = azurerm_resource_group.kubernetes_terraform.name
  address_space       = [var.vnet_CIDR]

  #   subnet {
  #     name           = "subnet-0"
  #     address_prefix = var.subnet_address_prefix
  #     security_group = azurerm_network_security_group.kubernetes_nsg.id
  #   }
}

resource "azurerm_subnet" "vnet_main_subnet_0" {
  name                 = "subnet-0"
  resource_group_name  = azurerm_resource_group.kubernetes_terraform.name
  virtual_network_name = azurerm_virtual_network.vnet_main.name
  address_prefixes     = [var.subnet_address_prefix]
}


resource "azurerm_public_ip" "kubernetes_pip" {
  name                = "kubernetes-pip"
  location            = azurerm_resource_group.kubernetes_terraform.location
  resource_group_name = azurerm_resource_group.kubernetes_terraform.name
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "controller_pip" {
  name                = "controller-pip"
  location            = azurerm_resource_group.kubernetes_terraform.location
  resource_group_name = azurerm_resource_group.kubernetes_terraform.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "kubernetes_lb" {
  name                = "kubernetes-lb"
  location            = azurerm_resource_group.kubernetes_terraform.location
  resource_group_name = azurerm_resource_group.kubernetes_terraform.name
  frontend_ip_configuration {
    name                 = "kubernetes-public-ip-address"
    public_ip_address_id = azurerm_public_ip.kubernetes_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "lb_address_pool" {
  loadbalancer_id = azurerm_lb.kubernetes_lb.id
  name            = "lb-address-pool"
  // resource_group_name = azurerm_resource_group.kubernetes_terraform.name
}

resource "azurerm_network_interface" "controller_nic" {
  name                 = "controller-nic"
  resource_group_name  = azurerm_resource_group.kubernetes_terraform.name
  location             = azurerm_resource_group.kubernetes_terraform.location
  enable_ip_forwarding = "true"

  ip_configuration {
    name                          = "internal"
    private_ip_address            = "10.240.0.10"
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip.controller_pip.id
    subnet_id                     = azurerm_subnet.vnet_main_subnet_0.id
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "controller_nic_backend_address_pool_association" {
  network_interface_id    = azurerm_network_interface.controller_nic.id
  ip_configuration_name   = "controller-lb-association"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_address_pool.id
}
