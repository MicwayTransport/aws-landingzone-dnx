data "aws_iam_policy_document" "s3_policy_config" {
  count = try(var.log_buckets.enabled ? 1 : 0, 0)
  statement {
    sid    = "ConfigLogs"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${var.organization.name}-${var.account_name}-config-${data.aws_region.current.name}/*"
    ]
  }
  statement {
    sid    = "OrgAccounts"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = formatlist("arn:aws:iam::%s:root", try(values(var.log_buckets.allow_from_account_ids), []))
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${var.organization.name}-${var.account_name}-config-${data.aws_region.current.name}/*"
    ]
  }
  statement {
    sid    = "OrgAccountsAcl"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = formatlist("arn:aws:iam::%s:root", try(values(var.log_buckets.allow_from_account_ids), []))
    }
    actions = [
      "s3:GetBucketAcl",
      "s3:PutBucketAcl"
    ]
    resources = [
      "arn:aws:s3:::${var.organization.name}-${var.account_name}-config-${data.aws_region.current.name}"
    ]
  }
  statement {
    sid    = "ConfigLogsAcl"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions = [
      "s3:GetBucketAcl"
    ]
    resources = [
      "arn:aws:s3:::${var.organization.name}-${var.account_name}-config-${data.aws_region.current.name}"
    ]
  }
}

resource "aws_s3_bucket" "config" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = "${var.organization.name}-${var.account_name}-config-${data.aws_region.current.name}"
  lifecycle {
    ignore_changes = [versioning, grant]
  }
}


resource "aws_s3_bucket_lifecycle_configuration" "config" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = aws_s3_bucket.config[0].id

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

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = aws_s3_bucket.config[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "config" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = aws_s3_bucket.config[0].id
  rule { object_ownership = "BucketOwnerPreferred" }
}

resource "aws_s3_bucket_acl" "config" {
  count      = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket     = aws_s3_bucket.config[0].id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.config]
}

resource "aws_s3_bucket_policy" "config" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = aws_s3_bucket.config[0].id
  policy = data.aws_iam_policy_document.s3_policy_config[0].json
}


output "config_s3_bucket_name" {
  value = try(aws_s3_bucket.config[0].id, "")
}

output "config_s3_bucket_arn" {
  value = try(aws_s3_bucket.config[0].arn, "")
}
