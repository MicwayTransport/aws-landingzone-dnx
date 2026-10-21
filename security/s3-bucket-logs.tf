data "aws_iam_policy_document" "s3_policy_logs" {
  count = try(var.log_buckets.enabled ? 1 : 0, 0)
  statement {
    sid    = "CWLogs"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${var.organization.name}-${var.account_name}-logs-${data.aws_region.current.name}/*"
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
      "arn:aws:s3:::${var.organization.name}-${var.account_name}-logs-${data.aws_region.current.name}/*"
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
      "arn:aws:s3:::${var.organization.name}-${var.account_name}-logs-${data.aws_region.current.name}"
    ]
  }
  statement {
    sid    = "CWLogsAcl"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.amazonaws.com"]
    }
    actions = [
      "s3:GetBucketAcl"
    ]
    resources = [
      "arn:aws:s3:::${var.organization.name}-${var.account_name}-logs-${data.aws_region.current.name}"
    ]
  }
}

resource "aws_s3_bucket" "logs" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = "${var.organization.name}-${var.account_name}-logs-${data.aws_region.current.name}"
  lifecycle {
    ignore_changes = [versioning, grant]
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = aws_s3_bucket.logs[0].id

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

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = aws_s3_bucket.logs[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = aws_s3_bucket.logs[0].id
  rule { object_ownership = "BucketOwnerPreferred" }
}

resource "aws_s3_bucket_acl" "logs" {
  count      = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket     = aws_s3_bucket.logs[0].id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.logs]
}

resource "aws_s3_bucket_policy" "logs" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = aws_s3_bucket.logs[0].id
  policy = data.aws_iam_policy_document.s3_policy_logs[0].json
}

output "logs_s3_bucket_name" {
  value = try(aws_s3_bucket.logs[0].id, "")
}

output "logs_s3_bucket_arn" {
  value = try(aws_s3_bucket.logs[0].arn, "")
}
