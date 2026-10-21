module "backup_notifications" {
  for_each = { for backup in var.backup : backup.name => backup if try(backup.enabled, false) == true }
  source   = "git::https://github.com/DNXLabs/terraform-aws-sns.git?ref=0.2.5"

  sns_topic_name     = "${var.org_name}-backup"
  slack_endpoint     = try(each.value.notification_slack_endpoint, "")
  email              = try(each.value.notification_email, "")
  account_ids        = try(each.value.allow_from_account_ids, [])
  sns_kms_encryption = false
}

data "aws_kms_key" "backup_vault" {
  for_each = { for backup in var.backup : backup.name => backup if try(backup.enabled, false) == true && try(backup.kms_name, "") != "" }
  key_id   = "alias/${each.value.kms_name}"
}

module "backups" {
  for_each = { for backup in var.backup : backup.name => backup if try(backup.enabled, false) == true }
  source   = "git::https://github.com/DNXLabs/terraform-aws-backup?ref=3.0.4"

  enabled             = each.value.enabled
  name                = each.value.name
  selection_tag_key   = try(each.value.selection_tag_key, "Backup")
  selection_tag_value = try(each.value.selection_tag_value, "true")

  selection_resources = [] # "An array of strings that either contain Amazon Resource Names (ARNs) or match patterns of resources to assign to a backup plan"

  min_retention_days = try(each.value.min_retention_days, null)
  max_retention_days = try(each.value.max_retention_days, null)

  enable_aws_backup_vault_notifications = try(each.value.enable_aws_backup_vault_notifications, false)
  vault_notification_sns_topic_arn      = try(module.backup_notifications[each.value.name].aws_sns_topic_arn, var.notifications_sns_topic_arn)
  backup_vault_events                   = try(each.value.backup_vault_events, ["BACKUP_JOB_FAILED", "COPY_JOB_FAILED"])

  rules = try(each.value.rules, [])

  vault_kms_key_arn = try(each.value.kms_name, "") != "" ? try(data.aws_kms_key.backup_vault[each.key].arn, "") : ""
  
  # Apply the cross-account copy policy for workload accounts
  vault_policy = var.account_type == "workload" && try(each.value.copy_action.aws_account_id, "") != "" ? try(data.aws_iam_policy_document.allow_copy_data_back_into_account_policy[each.key].json, "") : ""
}
