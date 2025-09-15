# GCP Infrastructure Manager Deployment Commands

This folder contains Terraform configuration to create a service account with custom IAM role bindings and predefined role bindings, supporting deployment at organization, folder, or project levels. Choose the appropriate command based on your desired binding target type.

## Required Parameters

- `YOUR_GCP_REGION`: The GCP region where the deployment will be created
- `YOUR_GCP_PROJECT_ID`: The GCP project ID where the service account will be created
- `YOUR_ORGANIZATION_ID`: The numerical ID of your GCP organization (required for org/folder bindings)
- `YOUR_FOLDER_ID`: The numerical ID of the folder (required for folder binding)

## Optional Parameters

- `sa_name`: Service account ID (default: "cloudflow-connection-sa")
- `custom_role_id`: Custom role ID (default: "cloudflowConnectionRole")
- `custom_role_permissions`: List of permissions for the custom role
- `predefined_roles`: List of predefined GCP roles to bind to the service account (e.g., ["roles/viewer", "roles/editor"])
- `trusted_token_creator_sa`: Service account that can create tokens (default: doit-connect@me-doit-intl-com.iam.gserviceaccount.com)

## Notes

- The service account is always created at the project level
- Custom roles are created at the organization level for org/folder bindings, or project level for project bindings
- The deployment will create a service account, custom IAM role, and bind both the custom role and predefined roles to the service account at the specified target level
- Predefined roles are bound alongside the custom role, providing additional permissions to the service account
- List parameters (custom_role_permissions and predefined_roles) are passed as comma-separated scalar values and split into lists of strings inside the Terraform script itself. This approach is used due to GCP Infrastructure Manager CLI limitations with the `--input-values` parameter, which primarily supports simple scalar values rather than complex data structures like lists or maps

## Examples of Predefined Roles

Common predefined roles you might want to include:

- `roles/viewer`: Read-only access to resources
- `roles/editor`: Read and write access to resources
- `roles/owner`: Full access to resources
- `roles/compute.viewer`: Read-only access to Compute Engine resources
- `roles/storage.objectViewer`: Read-only access to Cloud Storage objects
- `roles/bigquery.dataViewer`: Read-only access to BigQuery data
- `roles/logging.viewer`: Read-only access to Cloud Logging

## Deployment Commands by Binding Level

### 1. Organization-level Binding

Use this command to bind the custom role and predefined roles to the service account at the organization level:

```bash
gcloud infra-manager deployments apply cloudflow-connection-sa-org-deployment \
    --location=GCP_REGION \
    --service-account=projects/GCP_PROJECT_ID/serviceAccounts/DEPLOYMENT_SERVICE_ACCOUNT@developer.gserviceaccount.com \
    --project=GCP_PROJECT_ID \
    --terraform-source-gcs="gs://doit-public-bucket/cloudflow/create_cloudflow_connection_sa/" \
    --input-values="^;^sa_name=cloudflow-connection-sa;project_id=GCP_PROJECT_ID;custom_role_id=cloudflowConnectionRole;organization_id=ORGANIZATION_ID;iam_binding_target_type=organization;trusted_token_creator_sa=doit-connect@me-doit-intl-com.iam.gserviceaccount.com;custom_role_permissions=compute.instances.get,compute.instances.list,compute.disks.get,compute.disks.list,storage.objects.get,storage.objects.list;predefined_roles=roles/bigquery.dataViewer,roles/logging.viewer"
```

### 2. Folder-level Binding

Use this command to bind the custom role and predefined roles to the service account at the folder level:

```bash
gcloud infra-manager deployments apply cloudflow-connection-sa-folder-deployment \
    --location=GCP_REGION \
    --service-account=projects/GCP_PROJECT_ID/serviceAccounts/DEPLOYMENT_SERVICE_ACCOUNT@developer.gserviceaccount.com \
    --project=GCP_PROJECT_ID \
    --terraform-source-gcs="gs://doit-public-bucket/cloudflow/create_cloudflow_connection_sa/" \
    --input-values="^;^sa_name=cloudflow-connection-sa;project_id=GCP_PROJECT_ID;custom_role_id=cloudflowConnectionRole;organization_id=ORGANIZATION_ID;folder_id=FOLDER_ID;iam_binding_target_type=folder;trusted_token_creator_sa=doit-connect@me-doit-intl-com.iam.gserviceaccount.com;custom_role_permissions=compute.instances.get,compute.instances.list,compute.disks.get,compute.disks.list,storage.objects.get,storage.objects.list;predefined_roles=roles/bigquery.dataViewer,roles/logging.viewer"
```

### 3. Project-level Binding

Use this command to bind the custom role and predefined roles to the service account at the project level:

```bash
gcloud infra-manager deployments apply cloudflow-connection-sa-project-deployment \
    --location=GCP_REGION \
    --service-account=projects/GCP_PROJECT_ID/serviceAccounts/DEPLOYMENT_SERVICE_ACCOUNT@developer.gserviceaccount.com \
    --project=GCP_PROJECT_ID \
    --terraform-source-gcs="gs://doit-public-bucket/cloudflow/create_cloudflow_connection_sa/" \
    --input-values="^;^sa_name=cloudflow-connection;project_id=GCP_PROJECT_ID;custom_role_id=cloudflowConnectionRole;iam_binding_target_type=project;trusted_token_creator_sa=doit-connect@me-doit-intl-com.iam.gserviceaccount.com;custom_role_permissions=compute.instances.get,compute.instances.list;predefined_roles=roles/bigquery.dataViewer,roles/logging.viewer"
```
