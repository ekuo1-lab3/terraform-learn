terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_management_group" "l1" {
  display_name = "The Warehouse Group"
}

resource "azurerm_management_group" "l2" {
  for_each                   = toset(["Landing Zones", "Platform Shared"])
  display_name               = each.key
  parent_management_group_id = azurerm_management_group.l1.id
}

resource "azurerm_management_group" "l3" {
  for_each = tomap({
    "Non-production"  = "Landing Zones"
    "Production"      = "Landing Zones"
    "Sandbox"         = "Landing Zones"
    "Connectivity"    = "Platform Shared"
    "Identity"        = "Platform Shared"
    "Management"      = "Platform Shared"
    "Shared Services" = "Platform Shared"
  })
  display_name               = each.key
  parent_management_group_id = azurerm_management_group.l2[each.value].id
}

# Create new user
resource "azuread_user" "platform" {
  user_principal_name = "platform_shared_user@emilykuo5hotmail.onmicrosoft.com"
  display_name        = "Platform Shared User"
  password            = "123456789Mow"
}

resource "azurerm_role_assignment" "owner" {
  role_definition_name = "Owner"
  principal_id         = azuread_user.platform.object_id
  scope                = azurerm_management_group.l2["Platform Shared"].id
}

# Get existing user
data "azuread_user" "connectivity_user" {
  user_principal_name = "Connectivity@emilykuo5hotmail.onmicrosoft.com"
}

resource "azurerm_role_definition" "custom" {
  name        = "my-custom-role"
  scope       = azurerm_management_group.l3["Connectivity"].id
  description = "This is a custom role created via Terraform"

  permissions {
    actions     = ["*"]
    not_actions = []
  }
}

resource "azurerm_role_assignment" "custom" {
  role_definition_id = azurerm_role_definition.custom.role_definition_resource_id
  principal_id       = data.azuread_user.connectivity_user.object_id
  scope              = azurerm_management_group.l3["Connectivity"].id
}
