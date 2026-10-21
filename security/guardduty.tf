module "terraform-aws-guardduty" {
  count                = var.guardduty.alarms.enabled ? 1 : 0
  source               = "git::https://github.com/DNXLabs/terraform-aws-guardduty-alerts.git?ref=1.0.0"
  admin_account_id     = try(var.guardduty.admin_account_id, "")
  alarm_slack_severity = var.guardduty.alarms.enabled ? try(var.guardduty.alarms.alarm_slack_severity, "HIGH") : ""
  alarm_slack_webhook  = var.guardduty.alarms.enabled ? try(var.guardduty.alarms.slack_endpoint, "") : ""
  lambda_name          = var.guardduty.alarms.enabled ? try(var.guardduty.alarms.lambda_name, "guardduty-alarm") : ""
}
