
variable "tenant_id" {
  description = "Azure Tenant id"
  type        = string
}

variable "tenant_name" {
  description = "Azure Tenant name"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription id"
  type        = string
}

variable "my_public_ip" {
  description = "My laptop IP"
  type        = string
}

variable "shutdown_schedule" {
  description = "Schedule for when the VM should be turned off (UTC time)"
  type        = string
  default     = "18:00->8:00,Saturday,Sunday"
}

variable "automation_password" {
  description = "Password for automation user"
  type = string  
}