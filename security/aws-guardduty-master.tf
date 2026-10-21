resource "aws_guardduty_detector" "master" {
  count  = try(var.guardduty.enabled, false) && try(var.guardduty.role == "master", false) ? 1 : 0
  enable = true
}

resource "aws_guardduty_publishing_destination" "guardduty" {
  count           = try(var.guardduty.enabled, false) && try(var.guardduty.role == "master", false) ? 1 : 0
  detector_id     = aws_guardduty_detector.master[0].id
  destination_arn = try("arn:aws:s3:::${var.guardduty.bucket_name}", "")         #try(var.guardduty.bucket_name, false) == true ? "arn:aws:s3:::${try(var.guardduty.bucket_name, "")}" : "" 
  kms_key_arn     = try(var.guardduty.kms_key_arn, aws_kms_key.guardduty[0].arn) #aws_kms_key.s3_guardduty.arn
}

resource "aws_guardduty_member" "member" {
  for_each = { for member in try(var.organization.members, []) : member.account_id => member if try(var.guardduty.role, "member") == "master" }

  account_id  = each.value.account_id
  detector_id = aws_guardduty_detector.master[0].id
  email       = each.value.email
  invite      = true
}

### integration between guardduty -> cloudwatch -> event bridge -> chatbot

resource "aws_cloudwatch_event_rule" "guardduty" {
  count       = try(var.guardduty.enabled, false) && try(var.guardduty.role == "master", false) ? 1 : 0
  name_prefix = "GuardDutyFindings"
  description = "Captures Guard Duty New Findings"

  event_pattern = <<EOF
{
  "detail-type": [
    "GuardDuty Finding"
  ],
  "source": [
    "aws.guardduty"
  ]
}
EOF
}

resource "aws_cloudwatch_event_target" "guardduty" {
  count = try(var.guardduty.enabled, false) && try(var.guardduty.role == "master", false) ? 1 : 0

  target_id = "chatbot"
  rule      = aws_cloudwatch_event_rule.guardduty[0].name
  arn       = try(var.guardduty.alarms.sns_topic, "arn:aws:sns:${var.aws_region}:${var.guardduty.alarms.chatbot_aws_account_id}:chatbot-${var.guardduty.alarms.slack_channel}", "")
}




