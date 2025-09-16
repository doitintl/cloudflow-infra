# DoiT CloudFlow Infrastructure

This repository contains Infrastructure-as-Code (IaC) templates and modules for setting up secure cloud connections with the DoiT CloudFlow. 

## Overview

The repository provides automated infrastructure deployment scripts for establishing secure, cross-account connections between customer cloud environments and DoiT CloudFlow. These connections enable CloudFlow to collect metadata, provide insights, and manage cloud resources while maintaining security best practices through proper IAM roles and service accounts.

## Supported Cloud Providers

### Amazon Web Services (AWS)

- **CloudFormation Templates**: Declarative YAML templates for quick deployment
- **Terraform Modules**: Modular, reusable infrastructure code
- **IAM Role Creation**: Cross-account roles with external ID security
- **Flexible Permissions**: Support for both managed policies and custom actions

### Google Cloud Platform (GCP)

- **Terraform Modules**: Complete service account and IAM role management
- **Multi-Level Binding**: Organization, folder, or project-level permissions
- **Custom Role Creation**: Granular permission management
- **Token Creator Binding**: Secure service account impersonation

## Support and Documentation

Each cloud provider directory contains detailed README files with:

- Step-by-step deployment instructions
- Parameter descriptions and examples
- Troubleshooting guides
- Security considerations
- Best practices
