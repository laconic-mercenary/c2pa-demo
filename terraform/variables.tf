###########################
# Variables
# /project/terraform/variables.tf
###########################

variable "subscription_id" {
  default = "d6e52c18-b94e-4dab-ae31-9191b826429f"
}

variable "project_name" {
  description = "Name for all resources"
  type        = string
  default     = "mattc2pa"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "japaneast"
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "mattc2pa-rg01"
}

variable "storage_account_name" {
  description = "Globally unique name for the Azure Storage Account"
  type        = string
  default     = "mattc2pastacct01"
}

variable "key_vault_name" {
  description = "Name for the Azure Key Vault"
  type        = string
  default     = "mattc2pa-kv01"
}

variable "app_service_plan_name" {
  description = "App Service Plan for Function Apps"
  type        = string
  default     = "mattc2pa-asp01"
}

variable "function_app_sign_name" {
  description = "Function App for /sign endpoint"
  type        = string
  default     = "mattc2pa-fa-sign01"
}

variable "function_app_verify_name" {
  description = "Function App for /verify endpoint"
  type        = string
  default     = "mattc2pa-fa-verify01"
}
