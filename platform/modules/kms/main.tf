data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "app_key_policy" {
  for_each = { for key in var.app_kms_keys : key.name => key }

  statement {
    sid    = "EnableIAMUserPermissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowAppRoleToUseKey"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = each.value.allowed_iam_principals
    }
    actions   = ["kms:Encrypt", "kms:Decrypt", "kms:DescribeKey"]
    resources = ["*"]
  }
}

resource "aws_kms_key" "app_key" {
  for_each                = { for key in var.app_kms_keys : key.name => key }
  description             = each.value.description
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.app_key_policy[each.key].json
  tags                    = each.value.tags
}

resource "aws_kms_alias" "app_key_alias" {
  for_each      = { for key in var.app_kms_keys : key.name => key }
  name          = "alias/${each.key}"
  target_key_id = aws_kms_key.app_key[each.key].key_id
}