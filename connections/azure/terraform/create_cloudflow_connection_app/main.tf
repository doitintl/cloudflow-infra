# This Terraform script creates an Azure AD (Entra ID) application registration
# with a federated identity credential for DoiT CloudFlow (workload identity
# federation, no client secrets), a service principal, and role assignments at
# a specified scope (subscription, resource group, or management group).

terraform {
  required_version = ">= 1.0"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# --- Variables ---
# These variables allow to customize the application registration, the
# federated identity credential, and the role assignments.

variable "app_display_name" {
  description = "The display name of the application registration to create (e.g., doit-cloudflow-prod)."
  type        = string
  nullable    = false
  validation {
    condition     = length(var.app_display_name) >= 1 && length(var.app_display_name) <= 120
    error_message = "Application display name must be between 1 and 120 characters."
  }
}

variable "federation_issuer" {
  description = "The OIDC issuer of the DoiT broker identity trusted by the federated identity credential."
  type        = string
  default     = "https://accounts.google.com"
  validation {
    condition     = can(regex("^https://", var.federation_issuer))
    error_message = "Federation issuer must be an https:// URL."
  }
}

variable "federation_subject" {
  description = "The subject of the DoiT broker service account, as provided by the CloudFlow connection wizard."
  type        = string
  nullable    = false
  validation {
    condition     = length(var.federation_subject) >= 1
    error_message = "Federation subject must not be empty."
  }
}

variable "federation_audience" {
  description = "The audience of the federated identity credential, as provided by the CloudFlow connection wizard (e.g., api://doit-cloudflow/<customerId>/<connectionId>)."
  type        = string
  nullable    = false
  validation {
    condition     = length(var.federation_audience) >= 1
    error_message = "Federation audience must not be empty."
  }
}

variable "scope_path" {
  description = "The ARM scope where roles are assigned: /subscriptions/<guid>, /subscriptions/<guid>/resourceGroups/<name>, or /providers/Microsoft.Management/managementGroups/<id>."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^/subscriptions/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}(/resourceGroups/[^/]+)?$", var.scope_path)) || can(regex("^/providers/Microsoft\\.Management/managementGroups/[^/]+$", var.scope_path))
    error_message = "Scope path must be /subscriptions/<guid>, /subscriptions/<guid>/resourceGroups/<name>, or /providers/Microsoft.Management/managementGroups/<id>."
  }
}

variable "predefined_roles" {
  description = "A list of Azure built-in role names to assign to the service principal at the scope (e.g., [\"Reader\", \"Virtual Machine Contributor\"])."
  type        = list(string)
  default     = []
}

variable "custom_role_name" {
  description = "The name for a custom role definition. When set together with custom_role_actions, a custom role is created and assigned at the scope."
  type        = string
  default     = ""
}

variable "custom_role_actions" {
  description = "A list of ARM actions to include in the custom role (e.g., [\"Microsoft.Compute/virtualMachines/read\"]). Used only when custom_role_name is set."
  type        = list(string)
  default     = []
}

# --- Locals ---

locals {
  create_custom_role = var.custom_role_name != "" && length(var.custom_role_actions) > 0
}

# --- Resources ---

# --- 1. Create the Application Registration ---
resource "azuread_application" "cloudflow" {
  display_name = var.app_display_name
}

# --- 2. Create the Service Principal for the Application ---
resource "azuread_service_principal" "cloudflow" {
  client_id = azuread_application.cloudflow.client_id
}

# --- 3. Create the Federated Identity Credential ---
# This credential lets the DoiT CloudFlow broker identity authenticate as the
# application through workload identity federation, without any client secret.
resource "azuread_application_federated_identity_credential" "doit_cloudflow" {
  application_id = azuread_application.cloudflow.id
  display_name   = "doit-cloudflow"
  description    = "Federated identity credential for the DoiT CloudFlow connection"
  issuer         = var.federation_issuer
  subject        = var.federation_subject
  audiences      = [var.federation_audience]
}

# --- 4. Create the Custom Role ---
# This resource is created only when both custom_role_name and
# custom_role_actions are provided.
resource "azurerm_role_definition" "custom" {
  count       = local.create_custom_role ? 1 : 0
  name        = var.custom_role_name
  scope       = var.scope_path
  description = "Custom role defined by DoiT CloudFlow connection"

  permissions {
    actions     = var.custom_role_actions
    not_actions = []
  }

  assignable_scopes = [var.scope_path]
}

# --- 5. Assign Predefined Roles to the Service Principal ---
resource "azurerm_role_assignment" "predefined" {
  for_each             = toset(var.predefined_roles)
  scope                = var.scope_path
  role_definition_name = each.value
  principal_id         = azuread_service_principal.cloudflow.object_id
  principal_type       = "ServicePrincipal"
}

# --- 6. Assign the Custom Role to the Service Principal ---
resource "azurerm_role_assignment" "custom" {
  count              = local.create_custom_role ? 1 : 0
  scope              = var.scope_path
  role_definition_id = azurerm_role_definition.custom[0].role_definition_resource_id
  principal_id       = azuread_service_principal.cloudflow.object_id
  principal_type     = "ServicePrincipal"
}

# --- Outputs ---
# These outputs provide useful information about the created resources.

output "client_id" {
  description = "The application (client) ID of the created application registration. Paste this value into the CloudFlow connection wizard's deploy step."
  value       = azuread_application.cloudflow.client_id
}

output "service_principal_object_id" {
  description = "The object ID of the created service principal."
  value       = azuread_service_principal.cloudflow.object_id
}
