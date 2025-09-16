# AWS CloudFlow Connection Role Terraform Module

This Terraform module creates an IAM role for DoiT CloudFlow connections with configurable permissions and security controls.

## Overview

The module creates an IAM role that can be assumed by a trusted AWS account (default: DoiT's account) for CloudFlow integration purposes. It includes:

- Cross-account role assumption with external ID validation
- Configurable managed policy attachments
- Custom inline policy support for specific actions
- Base policy for CloudFlow connection requirements
- Region restriction to us-east-1 for compliance

## Features

- **Security**: Uses external ID for additional cross-account security
- **Flexibility**: Supports both managed policies and custom action lists
- **Compliance**: Enforces us-east-1 region deployment
- **Validation**: Input validation for role names, account IDs, and external IDs

## Requirements

- Terraform >= 1.0
- AWS Provider ~> 5.0
- AWS account with IAM permissions
- Deployment must be in us-east-1 region

## Usage

### Basic Usage

```hcl
module "cloudflow_connection_role" {
  source = "./create_cloudflow_connection_role.tf"

  role_name     = "my-cloudflow-role"
  external_id   = "unique-external-id-123"
  
  # Attach managed policies
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]
  
  # Define custom actions
  allowed_actions = [
    "ec2:DescribeInstances",
    "ec2:DescribeVolumes",    
    "s3:ListBuckets"
  ]
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `role_name` | Name of the IAM role to create | `string` | - | Yes |
| `external_id` | External ID for cross-account security | `string` | - | Yes |
| `trusted_account_id` | AWS Account ID allowed to assume the role | `string` | `"068664126052"` | No |
| `managed_policy_arns` | List of AWS managed policy ARNs to attach | `list(string)` | `[]` | No |
| `allowed_actions` | List of custom actions to allow | `list(string)` | `[]` | No |

### Variable Validation

- **role_name**: Must contain only alphanumeric characters and: `+=,.@_-`
- **external_id**: Must be 1-1224 characters, alphanumeric and: `+=,.@_-`
- **trusted_account_id**: Must be exactly 12 digits

## Outputs

| Name | Description |
|------|-------------|
| `role_arn` | ARN of the created IAM role |
| `role_name` | Name of the created IAM role |
| `role_id` | ID of the created IAM role |

## Resources Created

1. **IAM Role**: Main role with cross-account trust policy
2. **Base Policy**: Inline policy for CloudFlow connection requirements
3. **Custom Policy**: Optional inline policy for specified actions
4. **Policy Attachments**: Links managed policies and base policy to the role

## Security Features

- **External ID**: Required for cross-account role assumption
- **Trust Policy**: Restricts assumption to specified AWS account
- **Least Privilege**: Only grants specified permissions
- **Region Restriction**: Enforces us-east-1 deployment

### Prerequisites

1. Ensure you're in the us-east-1 region
2. Have appropriate AWS credentials configured
3. Terraform initialized in the module directory

### Commands

```bash
# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

## Example Output

```bash
$ terraform apply

Terraform will perform the following actions:

  # aws_iam_role.doit_cloudflow_connection_role will be created
  + resource "aws_iam_role" "doit_cloudflow_connection_role" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(...)
      + create_date          = (known after apply)
      + description          = "Role for DoiT CloudFlow connection"
      + id                   = (known after apply)
      + name                 = "my-cloudflow-role"
      + path                 = "/"
      + unique_id            = (known after apply)
    }

  # ... additional resources ...

Plan: 4 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to confirm.

  Enter a value: yes

aws_iam_role.doit_cloudflow_connection_role: Creating...
aws_iam_role.doit_cloudflow_connection_role: Creation complete after 2s [id=my-cloudflow-role]
...

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

role_arn = "arn:aws:iam::123456789012:role/my-cloudflow-role"
role_name = "my-cloudflow-role"
role_id = "my-cloudflow-role"
```
