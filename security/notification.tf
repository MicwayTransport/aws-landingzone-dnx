module "notifications" {
  count  = try(var.notifications.enabled ? 1 : 0, 0)
  source = "git::https://github.com/DNXLabs/terraform-aws-sns.git?ref=0.2.5"

  sns_topic_name     = var.organization.name
  slack_endpoint     = try(var.notifications.slack_endpoint, "")
  email              = try(var.notifications.email, "")
  account_ids        = try(var.notifications.allow_from_account_ids, [])
  sns_kms_encryption = true
}

output "notifications_sns_topic_arn" {
  value = try(module.notifications[0].aws_sns_topic_arn, "")
}
