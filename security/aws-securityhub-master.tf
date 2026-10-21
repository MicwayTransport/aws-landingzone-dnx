
module "securityhub" {
  count = try(var.securityhub.enabled, false) && try(var.securityhub.role == "master", false) ? 1 : 0

  source                    = "git::https://github.com/DNXLabs/terraform-aws-securityhub.git?ref=1.1.0"
  subscription_pci          = try(var.securityhub.subscriptions.pci, false)
  subscription_cis          = try(var.securityhub.subscriptions.cis, false)
  subscription_foundational = try(var.securityhub.subscriptions.foundational, false)
  members                   = try(var.organization.members, [])
  alarm_email               = try(var.securityhub.alarms.enabled ? try(var.securityhub.alarms.email, "") : "", "")
  alarm_slack_endpoint      = try(var.securityhub.alarms.enabled ? try(var.securityhub.alarms.slack_endpoint, "") : "", "")
  chatbot_sns_topic         = try(var.securityhub.alarms.sns_topic, "arn:aws:sns:${var.aws_region}:${try(var.securityhub.alarms.chatbot_aws_account_id, "")}:chatbot-${try(var.securityhub.alarms.slack_channel, "")}")

}
