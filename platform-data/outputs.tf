# IAM Users outputs
output "iam_users" {
  description = "Information about created IAM users"
  value = {
    for name, user in aws_iam_user.user : name => {
      user_name = user.name
      user_arn  = user.arn
      policy_arn = aws_iam_policy.user[name].arn
    }
  }
  sensitive = false
}

# Secrets Manager secret names for access keys (externally managed)
output "iam_user_secrets" {
  description = "Secrets Manager secret names containing IAM user access keys (managed externally)"
  value = {
    for name, secret in aws_secretsmanager_secret.external_key_placeholder : name => {
      secret_name = secret.name
      secret_arn  = secret.arn
      management  = "external"
      status      = "placeholder_created"
      next_step   = "Create access keys manually and store in this secret"
    }
  }
  sensitive = false
}

# External key management information
output "external_key_management_info" {
  description = "Information about external key management setup"
  value = {
    approach = "External Key Management - keys are NOT stored in Terraform state"
    security_benefit = "Access keys are never stored in Terraform state files"
    key_creation = "Keys must be created manually using AWS CLI or Console"
    key_storage = "Keys are stored directly in AWS Secrets Manager"
    terraform_role = "Terraform only manages IAM users and bucket policies, not access keys"
  }
  sensitive = false
}

# S3 buckets outputs
output "s3_buckets" {
  description = "Information about created S3 buckets"
  value = {
    for name, bucket in module.s3 : name => {
      bucket_name = bucket.bucket_name
      bucket_arn  = bucket.bucket_arn
    }
  }
  sensitive = false
}


output "redis_auth_tokens" {
  description = "Secrets Manager secret names containing Redis auth tokens"
  value = {
    for name, secret in aws_secretsmanager_secret.redis_auth_token : name => {
      secret_name = secret.name
      secret_arn  = secret.arn
    }
  }
  sensitive = true
}
