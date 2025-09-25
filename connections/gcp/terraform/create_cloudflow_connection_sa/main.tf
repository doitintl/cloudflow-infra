# This Terraform script creates a GCP service account, a custom IAM role,
# and then binds that custom role to the service account at a specified level
# (organization, folder, or project).

# --- Variables ---
# These variables allow to customize the service account and custom role.

variable "sa_name" {
  description = "The ID of the service account to create (e.g., my-app-sa). Must be unique within the project."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{5,29}$", var.sa_name))
    error_message = "Service account name must be 6-30 characters long, start with a lowercase letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "project_id" {
  description = "The ID of the GCP project where the service account will be created. Service accounts are always project-level resources."
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be 6-30 characters long, start with a lowercase letter, end with a lowercase letter or number, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "custom_role_id" {
  description = "The ID for the custom role (e.g., myCustomViewerRole). Must be unique at its creation level."
  type        = string
  nullable     = false
  validation {
    condition     = var.custom_role_id == "" || can(regex("^[a-zA-Z0-9_.]{3,64}$", var.custom_role_id))
    error_message = "Custom role ID must be 3-64 characters long and contain only letters, numbers, underscores, and periods."
  }
}

variable "predefined_roles" {
  description = "A list of predefined roles to include in the custom role (e.g., [\"roles/viewer\", \"roles/editor\"])."
  type        = string
  default     = ""
}

variable "custom_role_permissions" {
  description = "A list of permissions to include in the custom role (e.g., [\"compute.instances.get\", \"storage.objects.list\"]). \"iam.roles.get\" and \"cloudasset.assets.searchAllIamPolicies\" will always be included."
  type        = string
  default     = ""
}

variable "organization_id" {
  description = "The numerical ID of your GCP organization. Required if iam_binding_target_type is 'organization' or 'folder'."
  type        = string
  default     = null
  validation {
    condition     = var.organization_id == null || can(regex("^[0-9]{12,20}$", var.organization_id))
    error_message = "Organization ID must be a 12-20 digit numerical ID."
  }
}

variable "iam_binding_target_type" {
  description = "The type of resource to bind the role to ('organization', 'folder', or 'project')."
  type        = string
  nullable    = false
  validation {
    condition     = contains(["organization", "folder", "project"], var.iam_binding_target_type)
    error_message = "The iam_binding_target_type must be 'organization', 'folder', or 'project'."
  }
}

variable "folder_id" {
  description = "The numerical ID of the folder to bind the role to. Required if iam_binding_target_type is 'folder'."
  type        = string
  default     = null
  validation {
    condition     = var.folder_id == null || can(regex("^[0-9]{12,20}$", var.folder_id))
    error_message = "Folder ID must be a 12-20 digit numerical ID."
  }
}

variable "trusted_token_creator_sa" {
  description = "The service account that will be granted the token creator role on the created service account (e.g., doit-connect@me-doit-intl-com.iam.gserviceaccount.com)."
  type        = string
  default     = "doit-connect@me-doit-intl-com.iam.gserviceaccount.com"
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.trusted_token_creator_sa))
    error_message = "Trusted token creator service account must be a valid email address format."
  }
  validation {
    condition     = can(regex(".*@.*\\.iam\\.gserviceaccount\\.com$", var.trusted_token_creator_sa))
    error_message = "Trusted token creator service account must be a valid GCP service account email ending with .iam.gserviceaccount.com."
  }
}

# --- Provider Configuration ---
provider "google" {
  project = var.project_id
}

# --- Locals ---
# Generate human-readable titles from IDs and process variable inputs

locals {
  # Generate service account display name from sa_name
  sa_display_name = replace(
    replace(
      title(replace(var.sa_name, "/[-_]/", " ")),
      " ", " "
    ),
    "/\\s+/", " "
  )

  # Generate custom role title from custom_role_id
  custom_role_title = replace(
    replace(
      title(replace(var.custom_role_id, "/[-_]/", " ")),
      " ", " "
    ),
    "/\\s+/", " "
  )

  # Convert comma-separated string to a list and filter out empty strings
  predefined_roles_list = toset(var.predefined_roles != "" ? [for role in split(",", var.predefined_roles) : role if role != ""] : [])

  # Required permissions that should always be included
  required_permissions = ["iam.roles.get", "cloudasset.assets.searchAllIamPolicies"]
  
  # Convert comma-separated string to a list and filter out empty strings
  user_permissions = var.custom_role_permissions != "" ? [for permission in split(",", var.custom_role_permissions) : trimspace(permission) if trimspace(permission) != ""] : []
  
  # Merge and deduplicate user defined custom permissions with required permissions
  custom_role_permissions_list = toset(concat(local.required_permissions, local.user_permissions))
}

# --- Resources ---

# --- 1. Create the GCP Service Account ---
# Service accounts are always created within a specific project.
resource "google_service_account" "custom_sa" {
  account_id   = var.sa_name
  display_name = local.sa_display_name
  description  = "Service account created by DoiT CloudFlow connection"
  project      = var.project_id
}

# --- 2. Create the Custom Role ---
# This section conditionally creates the custom role at either the organization
# or project level based on the 'custom_role_creation_level' variable.

# Custom role created at the Organization level
resource "google_organization_iam_custom_role" "org_custom_role" {
  # This resource is created if binding to organization or folder (roles must be created at org level for folder binding)
  count       = (var.iam_binding_target_type == "organization" || var.iam_binding_target_type == "folder") && length(local.custom_role_permissions_list) > 0 ? 1 : 0
  role_id     = var.custom_role_id
  title       = local.custom_role_title
  description = "Custom role defined by DoiT CloudFlow connection"
  permissions = local.custom_role_permissions_list
  org_id      = var.organization_id
  stage       = "GA" # Recommended for production use
}

# Custom role created at the Project level
resource "google_project_iam_custom_role" "project_custom_role" {
  # This resource is created only if binding to project level
  count       = var.iam_binding_target_type == "project" && length(local.custom_role_permissions_list) > 0 ? 1 : 0
  role_id     = var.custom_role_id
  title       = local.custom_role_title
  description = "Custom role defined by DoiT CloudFlow connection"
  permissions = local.custom_role_permissions_list
  project     = var.project_id
  stage       = "GA" # Recommended for production use
}

# --- 3. Bind the Custom Role to the Service Account ---
# This section conditionally binds the custom role to the service account
# at the specified target resource level (organization, folder, or project).

# Binding at Organization level
resource "google_organization_iam_member" "org_binding" {
  # This binding is created if the target type is 'organization'.
  count  = var.iam_binding_target_type == "organization" && length(local.custom_role_permissions_list) > 0 ? 1 : 0
  org_id = var.organization_id
  role   = google_organization_iam_custom_role.org_custom_role[0].name
  member = "serviceAccount:${google_service_account.custom_sa.email}"
}

# Binding at Folder level
resource "google_folder_iam_member" "folder_binding" {
  # This binding is created if the target type is 'folder'.
  count  = var.iam_binding_target_type == "folder" && length(local.custom_role_permissions_list) > 0 ? 1 : 0
  folder = var.folder_id
  role   = google_organization_iam_custom_role.org_custom_role[0].name
  member = "serviceAccount:${google_service_account.custom_sa.email}"
}

# Binding at Project level
resource "google_project_iam_member" "project_binding" {
  # This binding is created if the target type is 'project'.
  count   = var.iam_binding_target_type == "project" && length(local.custom_role_permissions_list) > 0 ? 1 : 0
  project = var.project_id
  role    = google_project_iam_custom_role.project_custom_role[0].name
  member  = "serviceAccount:${google_service_account.custom_sa.email}"
}

# --- 4. Bind Predefined Roles to the Service Account ---
# This section conditionally binds predefined roles to the service account
# at the specified target resource level (organization, folder, or project).

# Predefined role bindings at Organization level
resource "google_organization_iam_member" "org_predefined_bindings" {
  # This binding is created for each predefined role if the target type is 'organization'.
  for_each = var.iam_binding_target_type == "organization" ? local.predefined_roles_list : []
  org_id   = var.organization_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.custom_sa.email}"
}

# Predefined role bindings at Folder level
resource "google_folder_iam_member" "folder_predefined_bindings" {
  # This binding is created for each predefined role if the target type is 'folder'.
  for_each = var.iam_binding_target_type == "folder" ? local.predefined_roles_list : []
  folder   = var.folder_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.custom_sa.email}"
}

# Predefined role bindings at Project level
resource "google_project_iam_member" "project_predefined_bindings" {
  # This binding is created for each predefined role if the target type is 'project'.
  for_each = var.iam_binding_target_type == "project" ? local.predefined_roles_list : []
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.custom_sa.email}"
}

# --- Service Account Token Creator Binding ---
# This binding allows the created service account to create tokens for other service accounts
resource "google_service_account_iam_member" "token_creator_binding" {
  service_account_id = google_service_account.custom_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${var.trusted_token_creator_sa}"
}

# --- Outputs ---
# These outputs provide useful information about the created resources.

output "service_account_email" {
  description = "The email address of the created service account."
  value       = google_service_account.custom_sa.email
}

output "custom_role_full_name" {
  description = "The full resource name of the created custom role."
  value = var.iam_binding_target_type == "project" ? (
    length(local.custom_role_permissions_list) > 0 ? google_project_iam_custom_role.project_custom_role[0].name : null
    ) : (
    length(local.custom_role_permissions_list) > 0 ? google_organization_iam_custom_role.org_custom_role[0].name : null
  )
}

output "custom_role_creation_level_used" {
  description = "The level at which the custom role was created."
  value       = var.iam_binding_target_type == "project" ? "project" : "organization"
}

output "iam_binding_target_resource_type" {
  description = "The type of resource where the custom role was bound."
  value       = var.iam_binding_target_type
}

output "iam_binding_target_resource_id" {
  description = "The ID of the resource where the custom role was bound."
  value = var.iam_binding_target_type == "organization" ? var.organization_id : (
    var.iam_binding_target_type == "folder" ? var.folder_id : var.project_id
  )
}
