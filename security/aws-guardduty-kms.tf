data "aws_iam_policy_document" "guardduty" {
  count = try(var.guardduty.enabled, false) && try(var.guardduty.role, false) == "master" ? 1 : 0

  statement {
    sid       = "Allow GuardDuty to encrypt findings"
    actions   = ["kms:GenerateDataKey"]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
  }
  statement {
    sid       = "Allow account to manage key"
    actions   = ["kms:*"]
    resources = ["arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
  statement {
    sid       = "Allow audit account to use log account KMS key"
    actions   = ["kms:GenerateDataKey"]
    resources = ["arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]

      # identifiers = ["arn:aws:iam::${try(var.log_buckets.allow_from_account_ids.audit, "")}:root"] # Audit account
    }
  }
}


resource "aws_kms_key" "guardduty" {
  count                   = try(var.guardduty.enabled, false) && try(var.guardduty.role, false) == "master" ? 1 : 0
  description             = "Guardduty KMS key"
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.guardduty[0].json
}


resource "aws_kms_alias" "guardduty" {
  count         = try(var.guardduty.enabled, false) && try(var.guardduty.role, false) == "master" ? 1 : 0
  name          = "alias/${var.organization.name}-guardduty"
  target_key_id = aws_kms_key.guardduty[0].key_id
}

output "guardduty_kms_key_arn" {
  value = try(aws_kms_key.guardduty[0].arn, "")
}

