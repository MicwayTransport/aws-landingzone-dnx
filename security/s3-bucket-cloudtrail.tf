
data "aws_iam_policy_document" "s3_policy_cloudtrail" {
  count = try(var.log_buckets.enabled ? 1 : 0, 0)
  statement {
    sid    = "CloudTrailAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::${var.organization.name}-${var.account_name}-cloudtrail-${data.aws_region.current.name}"]
  }
  statement {
    sid    = "CloudTrailWriteMaster"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = ["s3:PutObject"]
    resources = formatlist(
      "arn:aws:s3:::${var.organization.name}-${var.account_name}-cloudtrail-${data.aws_region.current.name}/AWSLogs/%s/*",
      [
        data.aws_organizations_organization.current.master_account_id,
        data.aws_organizations_organization.current.id
      ]
    )
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
  statement {
    sid    = "CloudTrailWriteAccounts"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = ["s3:PutObject"]
    resources = formatlist(
      "arn:aws:s3:::${var.organization.name}-${var.account_name}-cloudtrail-${data.aws_region.current.name}/AWSLogs/%s/*",
      try(values(var.log_buckets.allow_from_account_ids), [])
    )
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket" "cloudtrail" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = "${var.organization.name}-${var.account_name}-cloudtrail-${data.aws_region.current.name}"
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = aws_s3_bucket.cloudtrail[0].id

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

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = aws_s3_bucket.cloudtrail[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "cloudtrail" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = aws_s3_bucket.cloudtrail[0].id
  rule { object_ownership = "BucketOwnerPreferred" }
}

resource "aws_s3_bucket_acl" "cloudtrail" {
  count      = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket     = aws_s3_bucket.cloudtrail[0].id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.cloudtrail]
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = aws_s3_bucket.cloudtrail[0].id
  policy = data.aws_iam_policy_document.s3_policy_cloudtrail[0].json
}

output "cloudtrail_s3_bucket_name" {
  value = try(aws_s3_bucket.cloudtrail[0].id, "")
}

output "cloudtrail_s3_bucket_arn" {
  value = try(aws_s3_bucket.cloudtrail[0].arn, "")
}
