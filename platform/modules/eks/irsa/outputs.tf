# IRSA Submodule Outputs

output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = module.irsa.iam_role_arn
}

output "iam_role_name" {
  description = "Name of the IAM role"
  value       = module.irsa.iam_role_name
}

output "iam_role_unique_id" {
  description = "Unique ID of the IAM role"
  value       = module.irsa.iam_role_unique_id
}
