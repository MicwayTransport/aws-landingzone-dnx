resource "aws_s3_bucket" "frontend_app" {
  for_each      = { for app in try(var.frontend.apps, []) : app.name => app }
  bucket_prefix = "${each.value.name}-${each.value.environment_name}"

  #   server_side_encryption_configuration {
  #     rule {
  #       apply_server_side_encryption_by_default {
  #         kms_master_key_id = try(each.value.kms_key_arn, null)
  #         sse_algorithm     = each.value.kms_key_arn != null ? "aws:kms" : "AES256"
  #       }
  #     }
  #   }
}

resource "aws_s3_bucket_acl" "frontend_app" {
  for_each = { for app in try(var.frontend.apps, []) : app.name => app }
  bucket   = aws_s3_bucket.frontend_app[each.key].id
  acl      = "private"
}

module "frontend_app" {
  for_each = { for app in try(var.frontend.apps, []) : app.name => app }
  source   = "git::https://github.com/DNXLabs/terraform-aws-static-app.git?ref=2.5.1"

  providers = {
    aws           = aws
    aws.us-east-1 = aws.us-east-1
  }

  name         = "${each.value.name}-${each.value.environment_name}"
  s3_bucket_id = aws_s3_bucket.frontend_app[each.key].id

  cloudfront_logging_bucket = "${var.org_name}-log-archives-cloudfront-access-logs-${var.aws_region}.s3.amazonaws.com"
  cloudfront_logging_prefix = "${each.value.name}-${each.value.environment_name}"

  hostnames       = each.value.hostnames
  hostname_create = each.value.hostname_create
  certificate_arn = each.value.certificate_arn
  hosted_zone     = each.value.hosted_zone
}
