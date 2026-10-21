
data "aws_iam_policy_document" "kms_policy_config" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type = "AWS"
      #identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      identifiers = formatlist("arn:aws:iam::%s:root", local.all_account_ids)

    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
  statement {
    sid    = "Allow config to encrypt logs"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions   = ["kms:GenerateDataKey*", "kms:Decrypt"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = local.all_account_ids
    }
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

resource "aws_kms_key" "config" {
  count                   = try(var.config.enabled, false) && try(var.config.role, false) == "master" ? 1 : 0 #count  = try(var.log_buckets.enabled ? 1 : 0, 0 )
  deletion_window_in_days = 7
  description             = "Config Log Encryption Key"
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_policy_config.json
}

resource "aws_kms_alias" "config" {
  count         = try(var.config.enabled, false) && try(var.config.role, false) == "master" ? 1 : 0
  name          = "alias/${var.organization.name}-config"
  target_key_id = aws_kms_key.config[0].key_id
}

output "config_kms_key_arn" {
  value = try(aws_kms_key.config[0].arn, "")
}


