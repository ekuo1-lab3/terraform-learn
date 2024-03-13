terraform {
  required_version = ">= 1.1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "da0c5887-9e8b-43b3-83eb-5586c330a121" 
}

resource "azurerm_resource_group" "mtc-rg2" {
  name     = "mtc-rg2"
  location = "westus2"
  tags = {
    environment = "dev"
  }
}

resource "azurerm_virtual_network" "mtc-vn2" {
  name                = "mtc-vn2"
  resource_group_name = azurerm_resource_group.mtc-rg2.name
  location            = azurerm_resource_group.mtc-rg2.location
  address_space       = ["10.124.0.0/16"]

  tags = {
    environment = "dev"
  }
}

resource "azurerm_subnet" "mtc-subnet2" {
  name                 = "mtc-subnet2"
  resource_group_name  = azurerm_resource_group.mtc-rg2.name
  virtual_network_name = azurerm_virtual_network.mtc-vn2.name
  address_prefixes     = ["10.124.1.0/24"]
}

resource "azurerm_network_security_group" "mtc-sg2" {
  name                = "mtc-sg2"
  location            = azurerm_resource_group.mtc-rg2.location
  resource_group_name = azurerm_resource_group.mtc-rg2.name

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_security_rule" "mtc-dev-rule2" {
  name                        = "mtv-dev-rule2"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "103.51.113.10/32"
  resource_group_name         = azurerm_resource_group.mtc-rg2.name
  network_security_group_name = azurerm_network_security_group.mtc-sg2.name
}

resource "azurerm_subnet_network_security_group_association" "mtc-sga2" {
  subnet_id                 = azurerm_subnet.mtc-subnet2.id
  network_security_group_id = azurerm_network_security_group.mtc-sg2.id
}

resource "azurerm_public_ip" "mtc-ip2" {
  name                = "mtc-ip2"
  resource_group_name = azurerm_resource_group.mtc-rg2.name
  location            = azurerm_resource_group.mtc-rg2.location
  allocation_method   = "Dynamic"

  tags = {
    environment = "dev"
  }
}

resource "azurerm_network_interface" "mtc-nic2" {
  name                = "mtc-nic2"
  location            = azurerm_resource_group.mtc-rg2.location
  resource_group_name = azurerm_resource_group.mtc-rg2.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.mtc-subnet2.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mtc-ip2.id
  }

  tags = {
    environment = "dev"
  }
}

/*
resource "azurerm_linux_virtual_machine" "mtc-vm2" {
  name                = "mtc-vm2"
  resource_group_name = azurerm_resource_group.mtc-rg2.name
  location            = azurerm_resource_group.mtc-rg2.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.mtc-nic2.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/mtc_id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

*/