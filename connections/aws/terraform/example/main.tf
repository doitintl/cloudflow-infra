module "cloudflow_connection_role" {
  source = "../create_cloudflow_connection"

  role_name   = "my-cloudflow-role"
  external_id = "unique-external-id-123"

  # Attach managed policies
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]

  # Define custom actions
  allowed_actions = [
    "ec2:DescribeInstances",
    "s3:ListBuckets"
  ]
}
