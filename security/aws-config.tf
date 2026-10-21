locals {
  config_s3_bucket_name = try(var.config.s3_bucket_name, "${var.organization.name}-log-archives-config-${data.aws_region.current.name}")
}

resource "aws_iam_role" "config_role" {
  count       = try(var.config.enabled, false) ? 1 : 0
  name_prefix = "config-role-"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "config" {
  count      = try(var.config.enabled, false) ? 1 : 0
  role       = aws_iam_role.config_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_iam_role_policy" "config_s3" {
  count  = try(var.config.enabled, false) ? 1 : 0
  name   = "s3-policy"
  policy = data.aws_iam_policy_document.config_s3[0].json
  role   = aws_iam_role.config_role[0].name
}

data "aws_iam_policy_document" "config_s3" {
  count = try(var.config.enabled, false) ? 1 : 0
  statement {
    sid    = "1"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${local.config_s3_bucket_name}/prefix/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
    ]
    condition {
      test     = "StringLike"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control"
      ]
    }
  }
  statement {
    sid       = "2"
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::${local.config_s3_bucket_name}"]
  }
}

resource "aws_config_configuration_recorder" "recorder" {
  count    = try(var.config.enabled, false) ? 1 : 0
  name     = "default"
  role_arn = aws_iam_role.config_role[0].arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = try(var.config.global, false)
  }
}

resource "aws_config_delivery_channel" "bucket" {
  count          = try(var.config.enabled, false) ? 1 : 0
  depends_on     = [aws_config_configuration_recorder.recorder[0]]
  name           = "default"
  s3_bucket_name = local.config_s3_bucket_name
  s3_kms_key_arn = try(var.config.kms_key_arn, aws_kms_key.config[0].arn)
  s3_key_prefix  = ""

  snapshot_delivery_properties {
    delivery_frequency = "Three_Hours"
  }
}

resource "aws_config_configuration_recorder_status" "recorder" {
  count      = try(var.config.enabled, false) ? 1 : 0
  depends_on = [aws_config_delivery_channel.bucket[0]]
  name       = aws_config_configuration_recorder.recorder[0].id
  is_enabled = true
}
