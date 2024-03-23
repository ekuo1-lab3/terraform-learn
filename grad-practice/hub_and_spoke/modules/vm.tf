variable "resource_group" {
  description = "Resource Group arguments"
  type        = map(string)
}

variable "count_index" {
  description = "Count index number"
  type        = number
}

variable "route_table_id" {
  description = "Hub and Spoke route table id"
  type = string
}
  
variable "security_group_id" {
  description = "Network security group id"
  type        = string
}

variable "source_image" {
  description = "source_image map, including publisher, offer, sku, version"
  type        = map(string)
}

resource "azurerm_virtual_network" "this" {
  name                = "vn${var.count_index}"
  address_space       = ["10.${var.count_index}.0.0/16"]
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
}

resource "azurerm_subnet" "this" {
  name                 = "subnet${var.count_index}"
  resource_group_name  = var.resource_group.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.${var.count_index}.0.0/24"]
}

resource "azurerm_public_ip" "this" {
  name                = "pub-ip${var.count_index}"
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "this" {
  name                = "nic${var.count_index}"
  location            = var.resource_group.location
  resource_group_name = var.resource_group.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "config${var.count_index}"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

resource "azurerm_subnet_route_table_association" "this" {
  count = var.count_index != 0 ? 1 : 0
  subnet_id      = azurerm_subnet.this.id
  route_table_id = var.route_table_id 
}

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = var.security_group_id
}

# if linux vm
resource "azurerm_linux_virtual_machine" "this" {
  count = var.source_image.offer != "WindowsServer" ? 1 : 0

  name                = "vm${var.count_index}"
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
  size                = "Standard_B1ls"
  admin_username      = "adminuser"
  #admin_password      = "123456789Mow"
  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.source_image.publisher
    offer     = var.source_image.offer
    sku       = var.source_image.sku
    version   = var.source_image.version
  }
}

# if windows vm
resource "azurerm_windows_virtual_machine" "this" {
  count = var.source_image.offer == "WindowsServer" ? 1 : 0

  name                = "vm${var.count_index}"
  resource_group_name = var.resource_group.name
  location            = var.resource_group.location
  size                = "Standard_B1ls"
  admin_username      = "adminuser"
  admin_password      = "123456789Mow"
  network_interface_ids = [
    azurerm_network_interface.this.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = var.source_image.publisher
    offer     = var.source_image.offer
    sku       = var.source_image.sku
    version   = var.source_image.version
  }
}

# scheduling shutdown, but ignore for now
# https://stackoverflow.com/questions/52651326/create-azure-automation-start-stop-solution-through-terraform
# resource "azurerm_dev_test_global_vm_shutdown_schedule" "this" {
#   virtual_machine_id = azurerm_virtual_machine.this.id
#   location           = var.resource_group.location
#   enabled            = true

#   daily_recurrence_time = "1730"
#   timezone              = "AUS Eastern Standard Time"

#   notification_settings {
#     enabled = false
#   }
# }

output "ip-address" {
  description = "vm public ip address"
  value       = azurerm_public_ip.this.ip_address
}

output "virtual_network_info" {
  description = "Virtual network name and id"
  value       = { name = azurerm_virtual_network.this.name, id = azurerm_virtual_network.this.id }
}












