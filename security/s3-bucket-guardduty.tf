
data "aws_iam_policy_document" "s3_policy_guardduty" {
  count = try(var.log_buckets.enabled ? 1 : 0, 0)
  statement {
    sid       = "Allow PutObject"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${var.organization.name}-${var.account_name}-guardduty-${data.aws_region.current.name}/*"]
    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
  }
  statement {
    sid       = "Allow GetBucketLocation"
    actions   = ["s3:GetBucketLocation"]
    resources = ["arn:aws:s3:::${var.organization.name}-${var.account_name}-guardduty-${data.aws_region.current.name}"]
    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
  }
  statement {
    sid       = "Deny non-HTTPS access"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::${var.organization.name}-${var.account_name}-guardduty-${data.aws_region.current.name}/*"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}


# data "aws_iam_policy_document" "s3_guardduty_kms" {
#   statement {
#     sid       = "Allow GuardDuty to encrypt findings"
#     actions   = ["kms:GenerateDataKey"]
#     resources = ["*"]
#     principals {
#       type        = "Service"
#       identifiers = ["guardduty.amazonaws.com"]
#     }
#   }
#   statement {
#     sid       = "Allow account to manage key"
#     actions   = ["kms:*"]
#     resources = ["arn:aws:kms:${data.aws_region.current.name}:${var.guardduty.admin_account_id}:key/*"]
#     principals {
#       type        = "AWS"
#       identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root","arn:aws:iam::${var.guardduty.admin_account_id}:root"]
#     }
#   }
#   statement {
#     sid       = "Allow audit account to use log account KMS key"
#     actions   = ["kms:GenerateDataKey"]
#     resources = ["arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/*"]
#     principals {
#       type        = "AWS"
#       identifiers = ["arn:aws:iam::${try(var.log_buckets.allow_from_account_ids.audit, "")}:root"] # Audit account
#     }
#   }
# }

# resource "aws_kms_key" "s3_guardduty" {
#   count                   = try(var.log_buckets.enabled ? 1 : 0, 0 )
#   description             = "Guardduty S3 Key"
#   deletion_window_in_days = 7
#   policy                  = data.aws_iam_policy_document.s3_guardduty_kms.json
# }

# resource "aws_kms_alias" "kms_guardduty" {
#   count         = try(var.log_buckets.enabled ? 1 : 0, 0 )
#   name          = "alias/${var.organization.name}-guardduty"
#   target_key_id = aws_kms_key.s3_guardduty[0].key_id
# }

resource "aws_s3_bucket" "guardduty" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = "${var.organization.name}-${var.account_name}-guardduty-${data.aws_region.current.name}"
}


resource "aws_s3_bucket_lifecycle_configuration" "guardduty" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = aws_s3_bucket.guardduty[0].id

  rule {
    id     = "ARCHIVING"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = try(var.log_buckets.transition_to_glacier_in_days, 0)
      storage_class = "GLACIER"
    }
  }
}

# resource "aws_s3_bucket_server_side_encryption_configuration" "guardduty" {
#   count  = try(var.log_buckets.enabled ? 1 : 0, 0)
#   bucket = aws_s3_bucket.guardduty[0].id
#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }

resource "aws_s3_bucket_ownership_controls" "guardduty" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = aws_s3_bucket.guardduty[0].id
  rule { object_ownership = "BucketOwnerPreferred" }
}

resource "aws_s3_bucket_acl" "guardduty" {
  count      = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket     = aws_s3_bucket.guardduty[0].id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.guardduty]
}

resource "aws_s3_bucket_policy" "guardduty" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = aws_s3_bucket.guardduty[0].id
  policy = data.aws_iam_policy_document.s3_policy_guardduty[0].json
}

output "guardduty_s3_bucket_name" {
  value = try(aws_s3_bucket.guardduty[0].id, "")
}

output "guardduty_s3_bucket_arn" {
  value = try(aws_s3_bucket.guardduty[0].arn, "")
}
