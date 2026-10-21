module "notifications" {
  count  = var.notifications.enabled ? 1 : 0
  source = "git::https://github.com/DNXLabs/terraform-aws-sns.git?ref=0.2.5"

  sns_topic_name     = var.org_name
  slack_endpoint     = var.notifications.slack_endpoint
  email              = var.notifications.email
  account_ids        = var.notifications.account_ids
  sns_kms_encryption = true
}

output "notifications_sns_topic_arn" {
  value = try(module.notifications[0].aws_sns_topic_arn, "")
}