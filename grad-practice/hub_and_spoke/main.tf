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

# Common resource group
resource "azurerm_resource_group" "this" {
  name     = "rg"
  location = var.location
  tags = {
    "AutoShutdownSchedule" = "18:00->8:00,Saturday,Sunday"
  }
}

# Common network security group
resource "azurerm_network_security_group" "this" {
  name                = "sg"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_network_security_rule" "allow_ssh_sr" {
  name                        = "allow-ssh-sr"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.my_public_ip
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this.name
}

resource "azurerm_network_security_rule" "allow_rdp_sr" {
  name                        = "allow-rdp-sr"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this.name
}

resource "azurerm_network_security_rule" "allow_icmp_sr" {
  name                        = "allow-icmp-sr"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Icmp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this.name
}

resource "azurerm_route_table" "this" {
  name                = "spoke_route_table"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  route {
    name                   = "spoke1"
    address_prefix         = "10.1.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.0.4"
  }

  route {
    name                   = "spoke2"
    address_prefix         = "10.2.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.0.4"
  }
}

resource "azurerm_private_dns_zone" "this" {
  name                = "hub_spoke.com"
  resource_group_name = azurerm_resource_group.this.name
}

# Module import
module "vms" {
  count  = 3
  source = "./modules"

  resource_group        = { name = azurerm_resource_group.this.name, location = azurerm_resource_group.this.location }
  count_index           = count.index
  route_table_id        = azurerm_route_table.this.id
  security_group_id     = azurerm_network_security_group.this.id
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  source_image          = local.source_images[count.index]
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  count                     = 2
  name                      = "peer0to${count.index + 1}"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = module.vms[0].virtual_network_info.name
  remote_virtual_network_id = module.vms[count.index + 1].virtual_network_info.id
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  count                     = 2
  name                      = "peer${count.index + 1}to0"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = module.vms[count.index + 1].virtual_network_info.name
  remote_virtual_network_id = module.vms[0].virtual_network_info.id
  allow_forwarded_traffic   = true
}



output "pub_ip_output" {
  value = module.vms[*].ip-address
}



