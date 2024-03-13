variable "client_id" {
  description = "Service Principal id"
  type        = string
  sensitive   = true
}

variable "client_secret" {
  description = "Service Principal password"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure Tenant id"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription id"
  type        = string
}

variable "client_name" {
  description = "Service Principal display name"
  type        = string
}
