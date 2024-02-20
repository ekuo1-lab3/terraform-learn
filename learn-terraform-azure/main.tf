terraform {
  required_version = ">= 1.1.0"
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "myTFResourceGroup"
  location = "westus2"
}

resource "azurerm_virtual_network" "vnet" {
    address_space           = [
        "10.0.0.0/16",
    ]
    location                = "westus2"
    name                    = "myTFVnet"
    resource_group_name     = "myTFResourceGroup"
    subnet                  = []
    tags                    = {}

    timeouts {}
}
