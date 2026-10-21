remote_state {
  backend = "s3"
  generate = {
    path      = "_backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket  = "${local.globals.organization.name}-terraform-backend"
    key     = "${path_relative_to_include()}/terraform.tfstate"
    region  = local.globals.default_aws_region
    encrypt = true
    
    assume_role = {
      role_arn     = "arn:aws:iam::${local.accounts.accounts.shared-services.account_id}:role/TerraformBackendAccess"
      session_name = "terragrunt-session"
    }
    
    disable_bucket_update = true
  }
}