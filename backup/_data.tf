data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_organizations_organization" "current" {}

# Allow the backup center account to copy data back into the current account by adding permissions to your Backup vault.
data "aws_iam_policy_document" "allow_copy_data_back_into_account_policy" {
  for_each = {
    for backup in var.backup : backup.name => backup
    if var.account_type == "workload" && try(backup.enabled, false) && try(backup.copy_action.aws_account_id, "") != ""
  }

  statement {
    sid = "Allow ${each.value.copy_action.aws_account_id} to copy into vault-${each.key}"

    effect = "Allow"

    actions = [
      "backup:CopyIntoBackupVault"
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${each.value.copy_action.aws_account_id}:root"]
    }

    resources = ["*"]
  }
}

# Allow cross-account backup copy for accounts from the organization.
data "aws_iam_policy_document" "cross_account_copy_policy" {
  count = var.account_type == "backup" ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "backup:CopyIntoBackupVault"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values = [
        data.aws_organizations_organization.current.id
      ]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = ["*"]
  }
}
