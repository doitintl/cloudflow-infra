## What This Stack Does

1. Creates an IAM role with:
   - Trust policy allowing the specified trusted account to assume the role
   - External ID condition for additional security
   - Base policy allowing the role to get its own policy information
3. Conditionally attaches custom managed policies if ManagedPolicyArns is provided
4. Conditionally creates a custom inline policy with specific actions if AllowedActions is provided
5. Returns the ARN of the created role

## Parameters

- **RoleName**: The name of the IAM role to create (required)
- **TrustedAccountId**: AWS Account ID that is allowed to assume this role (default: 068664126052)
- **ExternalId**: External ID required for cross-account role assumption (required, provides additional security)
- **ManagedPolicyArns**: Comma-separated list of AWS managed policy ARNs to attach to the role (optional)
- **AllowedActions**: Comma-separated list of specific AWS actions to allow for the role (optional)

## Security Features

- **External ID**: Required when assuming the role, preventing confused deputy problems
- **Trusted Account**: Only the specified account can assume this role
- **Conditional Permissions**: CloudTrail access is only granted when explicitly requested
- **Flexible Policy Attachment**: Supports custom managed policies for specific use cases
- **Custom Actions**: Allows fine-grained control over specific AWS actions when needed

## Custom Actions Policy

When the `AllowedActions` parameter is provided with a comma-separated list of AWS actions, the stack creates a custom inline policy that grants the specified permissions. This allows for fine-grained control over the role's permissions without requiring managed policies.

Example actions that can be specified:
- `s3:GetObject,s3:ListBucket` - Read access to S3 buckets
- `ec2:DescribeInstances,ec2:DescribeVolumes` - EC2 read permissions
- `cloudwatch:GetMetricData,cloudwatch:ListMetrics` - CloudWatch monitoring permissions 

## CI/CD

Since we do not have a CI/CD pipeline for this CloudFormation template, manual deployment is required. After making any changes to the template file, please follow these steps:

1. **Upload the updated template**: Upload `create_cloudflow_connection_role.yml` (or a new version) to the AWS S3 bucket `doit-cmp-ops-pub` in the `cloudflow` folder
2. **Update the deployment link**: Ensure that links to the file in the code and documentation points to the correct version

# CloudFormation Stack Deployment Link

**Important: This stack must be deployed in the us-east-1 region only.**

## Quick Deploy Link

Use this link to deploy the CloudFormation stack that creates the IAM role for CloudFlow connection:

```
https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/quickcreate?templateUrl=https://doit-cmp-ops-pub.s3.us-east-1.amazonaws.com/cloudflow/create_cloudflow_connection_role.yml&stackName=DoitCloudFlowConnectionRole&param_RoleName=DoitCloudFlowConnectionRole&param_TrustedAccountId=068664126052&param_ExternalId=SomeProvidedExternalId&param_ManagedPolicyArns=arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess&param_AllowedActions=s3:GetObject,s3:ListBucket
```

## CLI Deployment Command

Use this AWS CLI command to deploy the stack:

```bash
aws cloudformation create-stack \
  --stack-name DoitCloudFlowConnectionRole \
  --template-url https://github.com/doitintl/cloudflow-infra/connections/aws/cloudformation/create_cloudflow_connection_role.yml \
  --parameters \
    ParameterKey=RoleName,ParameterValue=DoitCloudFlowConnectionRole \
    ParameterKey=TrustedAccountId,ParameterValue=068664126052 \
    ParameterKey=ExternalId,ParameterValue=SomeProvidedExternalId \
    ParameterKey=ManagedPolicyArns,ParameterValue="arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess" \
    ParameterKey=AllowedActions,ParameterValue="'s3:GetObject,s3:ListBucket'" \    
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### Check Stack Status

After running the create command, check the stack status:

```bash
aws cloudformation describe-stacks \
  --stack-name DoitCloudFlowConnectionRole \
  --region us-east-1 \
  --query 'Stacks[0].StackStatus'
```

### Get Stack Outputs

To get the role ARN after successful deployment:

```bash
aws cloudformation describe-stacks \
  --stack-name DoitCloudFlowConnectionRole \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`RoleArn`].OutputValue' \
  --output text
```
