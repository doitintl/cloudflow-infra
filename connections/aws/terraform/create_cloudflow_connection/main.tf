terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Variables (equivalent to CloudFormation Parameters)
variable "role_name" {
  description = "Name of the role to create or update"
  type        = string
  nullable    = false
  validation {
    condition     = can(regex("^[a-zA-Z0-9+=,.@_-]+$", var.role_name))
    error_message = "Role name must contain only alphanumeric characters and the following: +=,.@_-"
  }
}

variable "trusted_account_id" {
  description = "AWS Account ID that is allowed to assume this role"
  type        = string
  default     = "068664126052"
  validation {
    condition     = can(regex("^\\d{12}$", var.trusted_account_id))
    error_message = "Account ID must be exactly 12 digits"
  }
}

variable "external_id" {
  description = "External ID required for cross-account role assumption (provides additional security)"
  type        = string
  nullable    = false
  validation {
    condition     = length(var.external_id) >= 1 && length(var.external_id) <= 1224
    error_message = "External ID must be between 1 and 1224 characters"
  }
  validation {
    condition     = can(regex("^[a-zA-Z0-9+=,.@_-]+$", var.external_id))
    error_message = "External ID must contain only alphanumeric characters and the following: +=,.@_-"
  }
}

variable "managed_policy_arns" {
  description = "List of AWS managed policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "allowed_actions" {
  description = "List of actions to allow for the role"
  type        = list(string)
  default     = []
}

# Data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# Locals for conditional logic
locals {
  is_us_east_1         = data.aws_region.current.name == "us-east-1"
  has_managed_policies = length(var.managed_policy_arns) > 0
  has_allowed_actions  = length(var.allowed_actions) > 0
}

# Precondition check for us-east-1 region
resource "null_resource" "region_check" {
  count = local.is_us_east_1 ? 0 : 1

  lifecycle {
    precondition {
      condition     = local.is_us_east_1
      error_message = "This module must be deployed in us-east-1 region"
    }
  }
}

# Create the IAM role
resource "aws_iam_role" "doit_cloudflow_connection_role" {
  name        = var.role_name
  description = "Role for DoiT CloudFlow connection"
  path        = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.trusted_account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
        }
        Sid = "AllowAssumeRole"
      }
    ]
  })

  depends_on = [null_resource.region_check]
}

# Attach managed policies if provided
resource "aws_iam_role_policy_attachment" "managed_policies" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.doit_cloudflow_connection_role.name
  policy_arn = each.value

  depends_on = [aws_iam_role.doit_cloudflow_connection_role]
}

# Create the base inline policy for the role
resource "aws_iam_role_policy" "doit_cloudflow_connection_base_policy" {
  name = "DoitCloudFlowConnectionBasePolicy"
  role = aws_iam_role.doit_cloudflow_connection_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:GetRolePolicy"
        ]
        Effect   = "Allow"
        Resource = aws_iam_role.doit_cloudflow_connection_role.arn
        Sid      = "AllowListRolePolicies"
      },
      {
        Action = [
          "iam:GetPolicy",
          "iam:GetPolicyVersion"
        ]
        Effect   = "Allow"
        Resource = "*"
        Sid      = "AllowGetPolicy"
      },
      {
        Action = [
          "ec2:DescribeRegions"
        ]
        Effect   = "Allow"
        Resource = "*"
        Sid      = "AllowEC2DescribeRegions"
      }
    ]
  })

  depends_on = [aws_iam_role.doit_cloudflow_connection_role]
}

# Create the custom inline policy for the role if allowed actions are provided
resource "aws_iam_role_policy" "cloudflow_connection_role_custom_policy" {
  count = length(var.allowed_actions) > 0 ? 1 : 0

  name = "CloudFlowConnectionRoleCustomPolicy"
  role = aws_iam_role.doit_cloudflow_connection_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = var.allowed_actions
        Effect   = "Allow"
        Resource = "*"
        Sid      = "AllowActions"
      }
    ]
  })

  depends_on = [aws_iam_role.doit_cloudflow_connection_role]
}


output "role_arn" {
  description = "ARN of the created IAM role"
  value       = aws_iam_role.doit_cloudflow_connection_role.arn
}

output "role_name" {
  description = "Name of the created IAM role"
  value       = aws_iam_role.doit_cloudflow_connection_role.name
}

output "role_id" {
  description = "ID of the created IAM role"
  value       = aws_iam_role.doit_cloudflow_connection_role.id
}

output "base_policy_name" {
  description = "Name of the base inline policy"
  value       = aws_iam_role_policy.doit_cloudflow_connection_base_policy.name
}
