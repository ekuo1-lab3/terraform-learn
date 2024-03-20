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

locals {
  source_images = [
    {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts"
      version   = "latest"
    },
    {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts"
      version   = "latest"
    },
    {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2019-Datacenter"
      version   = "latest"
  }]
}

# Module import
module "vms" {
  count  = 3
  source = "./modules"

  location     = var.location
  count_index  = count.index
  my_public_ip = var.my_public_ip
  source_image = local.source_images[count.index]
}

output "pub_ip_output" {
  value = module.vms[*].ip-address
}
