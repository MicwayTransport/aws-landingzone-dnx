data "aws_iam_policy_document" "kms_policy_cmk" {
  for_each = { for key in try(var.kms_cmk, []) : key.name => key }

  statement {
    sid    = "Allow direct access to key metadata to the account"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = concat(["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"], formatlist("arn:aws:iam::%s:root", try(each.value.trust_account_ids, [])))
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = try(each.value.statements, [])
    content {
      effect = try(statement.value["effect"], "Allow")

      principals {
        type        = "AWS"
        identifiers = try(statement.value["identifiers"], [])
      }
      actions   = try(statement.value["actions"], [])
      resources = ["*"]
    }
  }

  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = each.value.name == "ecr" ? concat([join(",", try(each.value.trust_account_ids, []))], [data.aws_caller_identity.current.account_id]) : [data.aws_caller_identity.current.account_id]

    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["${lower(each.value.name)}.${data.aws_region.current.name}.amazonaws.com"]
    }
    sid = "Allow access for all principals in the account that are authorized to use the ${each.value.name} service"
  }
}

resource "aws_kms_key" "cmk" {
  for_each                = { for key in try(var.kms_cmk, []) : key.name => key }
  deletion_window_in_days = 30
  description             = "Customer-managed key that protects ${each.value.name} service"
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_policy_cmk[each.value.name].json
}

resource "aws_kms_alias" "cmk" {
  for_each      = { for key in try(var.kms_cmk, []) : key.name => key }
  name          = "alias/cmk/${lower(each.value.name)}"
  target_key_id = aws_kms_key.cmk[each.value.name].key_id
}
