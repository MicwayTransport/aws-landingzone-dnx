data "aws_canonical_user_id" "current" {} ## Human-friendly name linked to the canonical user ID. The bucket owner's display name. NOTE: This value is only included in the response in the US East (N. Virginia), US West (N. California), US West (Oregon), Asia Pacific (Singapore), Asia Pacific (Sydney), Asia Pacific (Tokyo), EU (Ireland), and South America (São Paulo) regions.

data "aws_iam_policy_document" "s3_policy_access_logs_cloudfront" {
  count = try(var.log_buckets.enabled ? 1 : 0, 0)
  statement {
    sid    = "deliveryLogsPolicy"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions = [
      "s3:PutObject",
      "s3:GetBucketAcl",
      "s3:PutBucketAcl"
    ]
    resources = [
      "arn:aws:s3:::${var.organization.name}-${var.account_name}-cloudfront-access-logs-${data.aws_region.current.name}",
      "arn:aws:s3:::${var.organization.name}-${var.account_name}-cloudfront-access-logs-${data.aws_region.current.name}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = values(try(var.log_buckets.allow_from_account_ids, {}))
    }

  }
  statement {
    sid    = "CloudfrontAccessLogsPolicy"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = formatlist("arn:aws:iam::%s:root", try(values(var.log_buckets.allow_from_account_ids), []))
    }
    actions = [
      "s3:GetBucketAcl",
      "s3:PutBucketAcl",
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::${var.organization.name}-${var.account_name}-cloudfront-access-logs-${data.aws_region.current.name}",
      "arn:aws:s3:::${var.organization.name}-${var.account_name}-cloudfront-access-logs-${data.aws_region.current.name}/*"
    ]
  }
}

resource "aws_s3_bucket" "cloudfront_access_logs" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = "${var.organization.name}-${var.account_name}-cloudfront-access-logs-${data.aws_region.current.name}"
  lifecycle {
    ignore_changes = [versioning, grant]
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_access_logs" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = aws_s3_bucket.cloudfront_access_logs[0].id

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

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_access_logs" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = aws_s3_bucket.cloudfront_access_logs[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_access_logs" {
  count = try(var.log_buckets.enabled ? 1 : 0, 0)

  bucket = aws_s3_bucket.cloudfront_access_logs[0].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "cloudfront_access_logs" {
  count = try(var.log_buckets.enabled ? 1 : 0, 0)

  depends_on = [aws_s3_bucket_ownership_controls.cloudfront_access_logs]

  bucket = aws_s3_bucket.cloudfront_access_logs[0].id
  access_control_policy {
    grant {
      grantee {
        id   = data.aws_canonical_user_id.current.id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }

    grant {
      grantee {
        id   = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0" #https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/AccessLogs.html
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }

    owner {
      id = data.aws_canonical_user_id.current.id
    }
  }
}

resource "aws_s3_bucket_policy" "cloudfront_access_logs" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = aws_s3_bucket.cloudfront_access_logs[0].id
  policy = data.aws_iam_policy_document.s3_policy_access_logs_cloudfront[0].json
}

output "cloudfront_access_logs_bucket_name" {
  value = try(aws_s3_bucket.cloudfront_access_logs[0].id, "")
}

output "cloudfront_access_logs_bucket_arn" {
  value = try(aws_s3_bucket.cloudfront_access_logs[0].arn, "")
}
