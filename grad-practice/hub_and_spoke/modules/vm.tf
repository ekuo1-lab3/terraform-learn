variable "location" {
  description = "Azure resource location"
  type        = string
}

variable "count_index" {
  description = "Count index number"
  type        = number
}

variable "my_public_ip" {
  description = "Laptop Public IP address"
  type        = string
}

variable "source_image" {
  description = "source_image map, including publisher, offer, sku, version"
  type        = map(string)
}

# Common resource group
resource "azurerm_resource_group" "this" {
  name     = "vm_rg${var.count_index}"
  location = var.location
}

resource "azurerm_virtual_network" "this" {
  name                = "vn"
  address_space       = ["10.${var.count_index}.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  name                 = "subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.${var.count_index}.0.0/24"]
}

resource "azurerm_public_ip" "this" {
  name                = "pub-ip"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "this" {
  name                = "nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "config1"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

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
  count                       = var.source_image.offer == "WindowsServer" ? 1 : 0
  name                        = "allow-rdp-sr"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = var.my_public_ip
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this.name
}

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_linux_virtual_machine" "this" {
  count = var.source_image.offer != "WindowsServer" ? 1 : 0

  name                = "linux-vm"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  size                = "Standard_B1ls"
  admin_username      = "adminuser"
  admin_password      = "123456789Mow"
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

resource "azurerm_windows_virtual_machine" "this" {
  count = var.source_image.offer == "WindowsServer" ? 1 : 0

  name                = "windows-vm"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
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

# https://stackoverflow.com/questions/52651326/create-azure-automation-start-stop-solution-through-terraform
# resource "azurerm_dev_test_global_vm_shutdown_schedule" "this" {
#   virtual_machine_id = azurerm_virtual_machine.this.id
#   location           = var.location
#   enabled            = true

#   daily_recurrence_time = "1730"
#   timezone              = "AUS Eastern Standard Time"

#   notification_settings {
#     enabled = false
#   }
# }

output "ip-address" {
  value = azurerm_public_ip.this.ip_address
}
