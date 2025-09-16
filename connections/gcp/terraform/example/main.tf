module "cloudflow_connection_sa" {
  source = "../create_cloudflow_connection_sa"

  sa_name                  = "my-cloudflow-sa"
  trusted_token_creator_sa = "doit-connect@doit-cloudflow-sa.iam.gserviceaccount.com"

  project_id              = "my-project-id"
  iam_binding_target_type = "organization"
  organization_id         = "123456789012"

  custom_role_id          = "my_custom_role_id"
  custom_role_permissions = "iam.roles.create, iam.roles.get"

  predefined_roles = "roles/viewer"

}
