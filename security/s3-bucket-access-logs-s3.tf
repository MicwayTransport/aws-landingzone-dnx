data "aws_iam_policy_document" "s3_policy_access_logs" {
  count = try(var.log_buckets.enabled ? 1 : 0, 0)
  statement {
    sid    = "S3ServerAccessLogsPolicy"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${var.organization.name}-${var.account_name}-s3-access-logs-${data.aws_region.current.name}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = values(try(var.log_buckets.allow_from_account_ids, {}))
    }
  }

}

resource "aws_s3_bucket" "s3_access_logs" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = "${var.organization.name}-${var.account_name}-s3-access-logs-${data.aws_region.current.name}"
  lifecycle {
    ignore_changes = [versioning, grant]
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_access_logs" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = aws_s3_bucket.s3_access_logs[0].id

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

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_access_logs" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = aws_s3_bucket.s3_access_logs[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "s3_access_logs" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = aws_s3_bucket.s3_access_logs[0].id
  rule { object_ownership = "BucketOwnerPreferred" }
}

resource "aws_s3_bucket_acl" "s3_access_logs" {
  count      = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket     = aws_s3_bucket.s3_access_logs[0].id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.s3_access_logs]
}

resource "aws_s3_bucket_policy" "s3_access_logs" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = aws_s3_bucket.s3_access_logs[0].id
  policy = data.aws_iam_policy_document.s3_policy_access_logs[0].json
}

output "s3_access_logs_bucket_name" {
  value = try(aws_s3_bucket.s3_access_logs[0].id, "")
}

output "s3_access_logs_bucket_arn" {
  value = try(aws_s3_bucket.s3_access_logs[0].arn, "")
}
