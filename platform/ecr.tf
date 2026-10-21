module "ecr_repository" {
  for_each         = { for repository in try(var.ecr.repositories, []) : repository.name => repository }
  source           = "git::https://github.com/DNXLabs/terraform-aws-ecr.git?ref=2.3.3"
  name             = each.value.name
  trust_accounts   = try(var.ecr.trust_account_ids, [])
  kms_key_arn      = try(var.ecr.kms_key_arn, "")
  lifecycle_policy = try(var.ecr.lifecycle_policy, "")
}

resource "aws_ecr_registry_scanning_configuration" "configuration" {
  count = length(try(var.ecr.repositories, [])) > 0 ? 1 : 0

  scan_type = try(var.ecr.scan_type, "BASIC")
  rule {
    scan_frequency = try(var.ecr.scan_type, "BASIC") == "BASIC" ? "SCAN_ON_PUSH" : try(var.ecr.repositories.scan_frequency, "CONTINUOUS_SCAN")

    repository_filter {
      filter      = "*"
      filter_type = "WILDCARD"
    }
  }
}

output "ecr_repository" {
  value = element(module.ecr_repository[*], 0)
}
