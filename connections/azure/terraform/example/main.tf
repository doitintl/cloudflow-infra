provider "azurerm" {
  features {}
  subscription_id = "00000000-0000-0000-0000-000000000000"
}

module "cloudflow_connection_app" {
  source = "../create_cloudflow_connection_app"

  app_display_name = "doit-cloudflow-prod"

  federation_subject  = "SUBJECT_FROM_CLOUDFLOW_WIZARD"
  federation_audience = "api://doit-cloudflow/CUSTOMER_ID/CONNECTION_ID"

  scope_path = "/subscriptions/00000000-0000-0000-0000-000000000000"

  predefined_roles = ["Reader"]

  custom_role_name    = "DoiT CloudFlow Connection Role"
  custom_role_actions = ["Microsoft.Compute/virtualMachines/read", "Microsoft.Compute/virtualMachines/start/action"]
}

output "client_id" {
  value = module.cloudflow_connection_app.client_id
}
