#https://automys.com/library/asset/scheduled-virtual-machine-shutdown-startup-microsoft-azure

resource "azurerm_automation_account" "this" {
  name                = "automation-account"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "Basic"
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Automation Credentials and Variables
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

resource "azurerm_automation_credential" "this" {
  name                    = "Default Automation Credential"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.this.name
  username                = azuread_user.this.user_principal_name
  password                = azuread_user.this.password
  description             = "Automation credential with RBAC owner to sub"
}

resource "azurerm_automation_variable_string" "subscription" {
  name                    = "Default Azure Subscription"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.this.name
  value                   = var.subscription_id
}

resource "azurerm_automation_variable_string" "tenant" {
  name                    = "Default Azure Tenant"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.this.name
  value                   = var.tenant_id
}

resource "azurerm_automation_variable_string" "tz" {
  name                    = "Default Time Zone"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.this.name
  value                   = "AUS Eastern Standard Time"
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Runbook 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

data "local_file" "this" {
  filename = "runbook.ps1"
}

resource "azurerm_automation_runbook" "this" {
  name                    = "start_stop_vm_scheduling"
  location                = azurerm_resource_group.this.location
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.this.name
  log_verbose             = "true"
  log_progress            = "true"
  description             = "Start and stop (deallocate) vms on a schedule. Define stopping times based on tags on resource group or VM"
  runbook_type            = "PowerShell"

  content = data.local_file.this.content
}

resource "azurerm_automation_schedule" "this" {
  name                    = "hourly-automation-schedule"
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.this.name
  frequency               = "Hour"
  interval                = 1
  timezone                = "Australia/Sydney"
  start_time              = "2024-03-28T06:00:00+00:00"
  description             = "Hourly schedule"
}

resource "azurerm_automation_job_schedule" "this" {
  resource_group_name     = azurerm_resource_group.this.name
  automation_account_name = azurerm_automation_account.this.name
  schedule_name           = azurerm_automation_schedule.this.name
  runbook_name            = azurerm_automation_runbook.this.name
}
