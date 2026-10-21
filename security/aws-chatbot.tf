locals {

  all_account_ids = concat([for member in try(var.organization.members, []) : member.account_id], [var.aws_account_id])

}
module "chatbot_alarms" {
  count  = try(var.chatbot.enabled, false) ? 1 : 0
  source = "git::https://github.com/DNXLabs/terraform-aws-chatbot?ref=3.0.0"

  org_name       = var.organization.name
  workspace_name = terraform.workspace
  slack_targets  = try(var.chatbot.slack_targets, []) #{ slack_channel_id = xxx, slack_workspace_id=xxx }
  account_ids    = try(var.chatbot.account_ids, local.all_account_ids)
  #kms_master_key_id   = TODO

}
