
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
  # set up service provider
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

# Creating multiple resource groups

# resource "azurerm_resource_group" "this" {
#   count    = 5
#   name     = "rg${count.index}"
#   location = "Australia East"
# }

#resource "azurerm_resource_group" "this" {
#  for_each = toset(["hello", "hi", "wow", "cat", "dog"])
#
#  name     = each.key
#  location = "Australia East"
#}

# Common resource group
resource "azurerm_resource_group" "rg" {
  name     = "vmm-rg"
  location = "Australia East"
}

# Common security stuff
resource "azurerm_network_security_group" "sg" {
  name                = "sg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "allow_ssh_sr" {
  name                        = "allow-ssh-sr"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "103.51.113.10/32"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.sg.name
}

# Module import
module "vms" {
  count = 2

  source = "./virtual_machine"

  resource_group    = { name = azurerm_resource_group.rg.name, location = azurerm_resource_group.rg.location }
  security_group_id = azurerm_network_security_group.sg.id
  count_index       = count.index
}

output "pub_ip_output" {
  value = module.vms[*].ip-address

}
