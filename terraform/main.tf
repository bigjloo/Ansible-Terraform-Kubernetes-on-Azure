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
    source_address_prefix      = "*"
    source_port_range          = "*"
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
}

resource "azurerm_subnet" "vnet_main_subnet_0" {
  name                 = "subnet-0"
  resource_group_name  = azurerm_resource_group.kubernetes_terraform.name
  virtual_network_name = azurerm_virtual_network.vnet_main.name
  address_prefixes     = [var.subnet_address_prefix]
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.vnet_main_subnet_0.id
  network_security_group_id = azurerm_network_security_group.kubernetes_nsg.id
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

resource "azurerm_public_ip" "workers_pip" {
  count               = var.worker_count
  name                = "worker-${count.index}-pip"
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
  ip_configuration_name   = azurerm_network_interface.controller_nic.ip_configuration[0].name
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_address_pool.id
}

resource "azurerm_linux_virtual_machine" "controller_vm" {
  name                  = "controller-vm"
  resource_group_name   = azurerm_resource_group.kubernetes_terraform.name
  location              = azurerm_resource_group.kubernetes_terraform.location
  size                  = "Standard_A2_v2"
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.controller_nic.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.path_to_ssh_pub_key)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}

resource "azurerm_availability_set" "worker_availability_set" {
  name                = "worker-availability-set"
  location            = azurerm_resource_group.kubernetes_terraform.location
  resource_group_name = azurerm_resource_group.kubernetes_terraform.name
}

resource "azurerm_network_interface" "workers_nic" {
  count                = var.worker_count
  name                 = "worker-${count.index}-nic"
  resource_group_name  = azurerm_resource_group.kubernetes_terraform.name
  location             = azurerm_resource_group.kubernetes_terraform.location
  enable_ip_forwarding = "true"

  ip_configuration {
    name                          = "internal"
    private_ip_address            = "10.240.0.2${count.index}"
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip.workers_pip[count.index].id
    subnet_id                     = azurerm_subnet.vnet_main_subnet_0.id
  }
}

resource "azurerm_linux_virtual_machine" "workers_vm" {
  count                 = var.worker_count
  name                  = "worker-${count.index}-vm"
  resource_group_name   = azurerm_resource_group.kubernetes_terraform.name
  location              = azurerm_resource_group.kubernetes_terraform.location
  size                  = "Standard_A2_v2"
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.workers_nic[count.index].id]
  availability_set_id   = azurerm_availability_set.worker_availability_set.id
  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.path_to_ssh_pub_key)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}
