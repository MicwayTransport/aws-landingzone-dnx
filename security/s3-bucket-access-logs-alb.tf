locals {
  elb_principal = {
    "us-east-1" : "127311923021"
    "us-east-2" : "033677994240"
    "us-west-1" : "027434742980"
    "us-west-2" : "797873946194"
    "af-south-1" : "098369216593"
    "ca-central-1" : "985666609251"
    "eu-central-1" : "054676820928"
    "eu-west-1" : "156460612806"
    "eu-west-2" : "652711504416"
    "eu-south-1" : "635631232127"
    "eu-west-3" : "009996457667"
    "eu-north-1" : "897822967062"
    "ap-east-1" : "754344448648"
    "ap-northeast-1" : "582318560864"
    "ap-northeast-2" : "600734575887"
    "ap-northeast-3" : "383597477331"
    "ap-southeast-1" : "114774131450"
    "ap-southeast-2" : "783225319266"
    "ap-south-1" : "718504428378"
    "me-south-1" : "076674570225"
    "sa-east-1" : "507241528517"
    "us-gov-west-1" : "048591011584"
    "us-gov-east-1" : "190560391635"
    "cn-north-1" : "638102146993"
    "cn-northwest-1" : "037604701340"
  }
}

data "aws_iam_policy_document" "s3_access_logs_policy" {
  count = try(var.log_buckets.enabled ? 1 : 0, 0)
  statement {
    sid    = "s3AccessLogsPolicySid1"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions = [
      "s3:GetBucketAcl"
    ]
    resources = [format("arn:aws:s3:::%s-${var.account_name}-alb-access-logs-%s", var.organization.name, data.aws_region.current.name)]
  }

  statement {
    sid    = "s3AccessLogsPolicyAcrossAccount"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = formatlist("arn:aws:s3:::${var.organization.name}-${var.account_name}-alb-access-logs-${data.aws_region.current.name}/%s/AWSLogs/%s/*",
      keys(try(var.log_buckets.allow_from_account_ids, {})),
    values(try(var.log_buckets.allow_from_account_ids, {})))

  }
  dynamic "statement" { ## new methetod uses logdelivery.elasticloadbalancing service 
    for_each = data.aws_region.current.name != "ap-southeast-4" ? [1] : []
    content {
      sid    = "s3AccessLogsPolicySid2"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${local.elb_principal[data.aws_region.current.name]}:root"]
      }
      actions = [
        "s3:PutObject"
      ]
      resources = formatlist("arn:aws:s3:::${var.organization.name}-${var.account_name}-alb-access-logs-${var.aws_region}/%s/AWSLogs/%s/*",
        keys(try(var.log_buckets.allow_from_account_ids, {})),
      values(try(var.log_buckets.allow_from_account_ids, {})))
    }
  }

  statement {
    sid    = "s3AccessLogsPolicySid3"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = formatlist("arn:aws:s3:::%s-${var.account_name}-alb-access-logs-%s/%s/AWSLogs/%s/*",
      var.organization.name,
      data.aws_region.current.name,
      keys(try(var.log_buckets.allow_from_account_ids, {})),
    values(try(var.log_buckets.allow_from_account_ids, {})))

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket" "alb_access_logs" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = "${var.organization.name}-${var.account_name}-alb-access-logs-${data.aws_region.current.name}"

  lifecycle {
    ignore_changes = [versioning, grant]
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_access_logs" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = aws_s3_bucket.alb_access_logs[0].id

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

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_access_logs" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = aws_s3_bucket.alb_access_logs[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "alb_access_logs" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = aws_s3_bucket.alb_access_logs[0].id
  rule { object_ownership = "BucketOwnerPreferred" }
}

resource "aws_s3_bucket_acl" "alb_access_logs" {
  count      = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket     = aws_s3_bucket.alb_access_logs[0].id
  acl        = "private"
  depends_on = [aws_s3_bucket_ownership_controls.alb_access_logs]
}

resource "aws_s3_bucket_policy" "alb_access_logs" {
  count  = try(var.log_buckets.enabled ? 1 : 0, 0)
  bucket = aws_s3_bucket.alb_access_logs[0].id
  policy = data.aws_iam_policy_document.s3_access_logs_policy[0].json
}

output "alb_access_logs_s3_bucket_name" {
  value = try(aws_s3_bucket.alb_access_logs[0].id, "")
}

output "alb_access_logs_s3_bucket_arn" {
  value = try(aws_s3_bucket.alb_access_logs[0].arn, "")
}
