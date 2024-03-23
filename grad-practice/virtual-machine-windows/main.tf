terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  # using the varsfrom variables.tf and secret.auto.tfvars
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "vm-rg" {
  name     = "vm-rg"
  location = "Australia East"
}

resource "azurerm_virtual_network" "vm-vn" {
  name                = "vm-vn"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.vm-rg.location
  resource_group_name = azurerm_resource_group.vm-rg.name
}

resource "azurerm_subnet" "vm-subnet" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.vm-rg.name
  virtual_network_name = azurerm_virtual_network.vm-vn.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "vm-pub-ip" {
  name                = "vm-pub-ip"
  resource_group_name = azurerm_resource_group.vm-rg.name
  location            = azurerm_resource_group.vm-rg.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "vm-nic" {
  name                = "vm-nic"
  location            = azurerm_resource_group.vm-rg.location
  resource_group_name = azurerm_resource_group.vm-rg.name

  ip_configuration {
    name                          = "vm-ip"
    subnet_id                     = azurerm_subnet.vm-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm-pub-ip.id
  }
}

resource "azurerm_network_security_group" "vm-sg" {
  name                = "vm-sg"
  location            = azurerm_resource_group.vm-rg.location
  resource_group_name = azurerm_resource_group.vm-rg.name
}

resource "azurerm_network_security_rule" "vm-allow-ssh-sr" {
  name                        = "vm-allow-ssh-sr"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.my_public_ip
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.vm-rg.name
  network_security_group_name = azurerm_network_security_group.vm-sg.name
}

resource "azurerm_subnet_network_security_group_association" "vm-sga" {
  subnet_id                 = azurerm_subnet.vm-subnet.id
  network_security_group_id = azurerm_network_security_group.vm-sg.id
}

resource "azurerm_windows_virtual_machine" "vm-vm" {
  name                = "vm-vm"
  resource_group_name = azurerm_resource_group.vm-rg.name
  location            = azurerm_resource_group.vm-rg.location
  size                = "Standard_DS1_v2"
  admin_username      = "adminuser"
  admin_password      = "123456789Mow"
  network_interface_ids = [
    azurerm_network_interface.vm-nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "smalldisk 2019-Datacenter"
    version   = "latest"
  }
}

output "ip-address" {
  value = azurerm_public_ip.vm-pub-ip.ip_address
}
