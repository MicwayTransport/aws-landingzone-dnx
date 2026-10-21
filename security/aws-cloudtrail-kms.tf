
data "aws_iam_policy_document" "kms_policy_cloudtrail" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
  statement {
    sid    = "Allow CloudTrail to encrypt logs"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["kms:GenerateDataKey*"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values = formatlist("arn:aws:cloudtrail:*:%s:trail/*", concat(
        [data.aws_caller_identity.current.account_id],
        try(values(var.log_buckets.allow_from_account_ids), [])
      ))
    }
  }
  statement {
    sid    = "Allow Lambda to describe key access"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com", "lambda.amazonaws.com"]
    }
    actions   = ["kms:GenerateDataKey*", "kms:DescribeKey"]
    resources = ["*"]

  }
  statement {
    sid    = "Allow CloudWatch Access"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logs.amazonaws.com", "cloudwatch.amazonaws.com"]
    }
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]

  }
}

resource "aws_kms_key" "cloudtrail" {
  count                   = try(var.cloudtrail.enabled, false) && try(var.cloudtrail.role, false) == "master" ? 1 : 0 #count  = try(var.log_buckets.enabled ? 1 : 0, 0 )
  deletion_window_in_days = 7
  description             = "CloudTrail Log Encryption Key"
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_policy_cloudtrail.json
}

resource "aws_kms_alias" "cloudtrail" {
  count         = try(var.cloudtrail.enabled, false) && try(var.cloudtrail.role, false) == "master" ? 1 : 0
  name          = "alias/${var.organization.name}-cloudtrail"
  target_key_id = aws_kms_key.cloudtrail[0].key_id
}

output "cloudtrail_kms_key_arn" {
  value = try(aws_kms_key.cloudtrail[0].arn, "")
}

