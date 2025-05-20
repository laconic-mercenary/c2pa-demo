###########################
# Root Terraform Config
# /project/terraform/main.tf
###########################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }

  required_version = ">= 1.3.0"
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

data "azurerm_client_config" "current" {}

###########################
# Resource Group
###########################
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

###########################
# Storage Account (Blob + Table)
###########################
resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "uploads" {
  name                  = "temp-upload"
  container_access_type = "private"
  storage_account_id = azurerm_storage_account.main.id
}

resource "azurerm_storage_container" "signed" {
  name                  = "signed-output"
  container_access_type = "private"
  storage_account_id = azurerm_storage_account.main.id
}

resource "azurerm_storage_table" "cert_metadata" {
  name                 = "certmetadata"
  storage_account_name = azurerm_storage_account.main.name
}

resource "azurerm_storage_management_policy" "cleanup_policy" {
  storage_account_id = azurerm_storage_account.main.id

  rule {
    name    = "delete-old-temp-uploads"
    enabled = true
    filters {
      prefix_match = ["temp-upload/"]
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 1
      }
    }
  }

  rule {
    name    = "cool-signed-output"
    enabled = true
    filters {
      prefix_match = ["signed-output/"]
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = 7
        delete_after_days_since_modification_greater_than       = 30
      }
    }
  }
}

###########################
###########################
# SAS Generator Function
###########################
resource "azurerm_user_assigned_identity" "sasgen" {
  name                = "sasgen-fn-identity"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_linux_function_app" "sasgen" {
  name                       = "${var.project_name}-sas-generator"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  service_plan_id            = azurerm_service_plan.shared.id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.sasgen.id]
  }

  site_config {
    application_stack {
      python_version = "3.10"
    }
  }
}


resource "azurerm_key_vault_access_policy" "sasgen" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.sasgen.principal_id

  secret_permissions      = ["Get", "List"]
  certificate_permissions = ["Get", "List"]
}

###########################
# Key Vault
###########################
resource "azurerm_key_vault" "main" {
  name                        = var.key_vault_name
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = true
}

resource "azurerm_key_vault_access_policy" "sign" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.sign.principal_id

  secret_permissions      = ["Get", "List"]
  certificate_permissions = ["Get", "List"]
}

resource "azurerm_key_vault_access_policy" "verify" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.verify.principal_id

  secret_permissions      = ["Get", "List"]
  certificate_permissions = ["Get", "List"]
}

###########################
# App Service Plan (shared)
###########################

resource "azurerm_service_plan" "shared" {
  name                = "shared-plan"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "Y1"
}


###########################
# Function App - /sign
###########################
resource "azurerm_user_assigned_identity" "sign" {
  name                = "sign-fn-identity"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_linux_function_app" "sign" {
  name                       = "${var.project_name}-sign"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  service_plan_id            = azurerm_service_plan.shared.id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.sign.id]
  }

  site_config {
    application_stack {
      java_version = "17"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "java"
  }

}

###########################
# Function App - /verify
###########################
resource "azurerm_user_assigned_identity" "verify" {
  name                = "verify-fn-identity"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_linux_function_app" "verify" {
  name                       = "${var.project_name}-verify"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  service_plan_id            = azurerm_service_plan.shared.id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.sign.id]
  }

  site_config {
    application_stack {
      java_version = "17"
    }
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "java"
  }

}

###
# Rust Test
###
resource "azurerm_linux_function_app" "rust_test" {
  name                       = "${var.project_name}-rust-test"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  service_plan_id            = azurerm_service_plan.shared.id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key
  
  site_config {
    application_stack {
      use_custom_runtime = true
    }
  }
}

###########################
# Certificate Renewal Infra
###########################
resource "azurerm_user_assigned_identity" "certbot_generate" {
  name                = "certbot-generate-identity"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_user_assigned_identity" "certbot_update" {
  name                = "certbot-update-identity"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_linux_function_app" "certbot_generate" {
  name                       = "${var.project_name}-certbot-generate"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  service_plan_id            = azurerm_service_plan.shared.id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key
  
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.certbot_generate.id]
  }

  site_config {
    application_stack {
      python_version = "3.10"
    }
  }
}

resource "azurerm_linux_function_app" "certbot_update" {
  name                       = "${var.project_name}-certbot-update"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  service_plan_id            = azurerm_service_plan.shared.id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key
  
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.certbot_update.id]
  }

  site_config {
    application_stack {
      python_version = "3.10"
    }
  }
}

resource "azurerm_key_vault_access_policy" "certbot_generate" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.certbot_generate.principal_id

  certificate_permissions = ["Create", "Get", "List"]
  secret_permissions      = ["Get", "List"]
}

resource "azurerm_key_vault_access_policy" "certbot_update" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.certbot_update.principal_id

  certificate_permissions = ["Get", "Import"]
  secret_permissions      = ["Get", "Set"]
}
###########################
resource "azurerm_user_assigned_identity" "certbot" {
  name                = "cert-bot-identity"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_linux_function_app" "certbot" {
  name                       = "${var.project_name}-cert-bot-time"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  service_plan_id            = azurerm_service_plan.shared.id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key
  
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.certbot.id]
  }

  site_config {
    application_stack {
      python_version = "3.10"
    }
  }
}

resource "azurerm_key_vault_access_policy" "certbot" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.certbot.principal_id

  secret_permissions      = ["Get", "List", "Set"]
  certificate_permissions = ["Get", "List", "Create", "Import"]
}

###########################
# RBAC Assignments
###########################
resource "azurerm_role_assignment" "certbot_table_access" {
  principal_id         = azurerm_user_assigned_identity.certbot.principal_id
  role_definition_name = "Storage Table Data Contributor"
  scope                = azurerm_storage_account.main.id
}

resource "azurerm_role_assignment" "sasgen_table_access" {
  principal_id         = azurerm_user_assigned_identity.sasgen.principal_id
  role_definition_name = "Storage Table Data Contributor"
  scope                = azurerm_storage_account.main.id
}

###########################
# Outputs
###########################
output "storage_account_name" {
  value = azurerm_storage_account.main.name
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

output "resource_group" {
  value = azurerm_resource_group.main.name
}

output "function_app_sign_url" {
  value = azurerm_linux_function_app.sign.default_hostname
}

output "function_app_verify_url" {
  value = azurerm_linux_function_app.verify.default_hostname
}
