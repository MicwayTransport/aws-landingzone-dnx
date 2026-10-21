data "aws_iam_policy_document" "policy_set_ecs_default" {
  count = contains(var.policy_sets, "ECS_DEFAULT") ? 1 : 0
  statement {
    sid = "staticapps"
    actions = [
      "s3:*",
      "cloudfront:CreateInvalidation",
    ]
    resources = ["*"]
  }
  statement {
    sid = "ecsecr"
    actions = [
      "ecs:Describe*",
      "ecs:List*",
      "ecs:RunTask",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
      "codedeploy:CreateDeployment",
      "codedeploy:Get*",
      "codedeploy:List*",
      "codedeploy:ContinueDeployment",
      "codedeploy:StopDeployment",
      "codedeploy:RegisterApplicationRevision",
      "ecr:*",
    ]
    resources = ["*"]
  }
  statement {
    sid = "eks"
    actions = [
      "eks:Describe*",
      "eks:List*",
      "eks:UpdateClusterConfig"
    ]
    resources = ["*"]
  }
  statement {
    sid = "elb"
    actions = [
      "elasticloadbalancing:Describe*",
    ]
    resources = ["*"]
  }
  statement {
    sid = "ssm"
    actions = [
      "ssm:List*",
      "ssm:Describe*",
      "ssm:Get*"
    ]
    resources = ["*"]
  }
  statement {
    sid = "logs"
    actions = [
      "logs:GetLogEvents",
      "logs:GetLogRecord",
      "logs:GetLogDelivery",
      "logs:GetLogGroupFields",
      "logs:GetQueryResults",
      "logs:FilterLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:StartQuery",
      "logs:StopQuery",
      "logs:TestMetricFilter",
    ]
    resources = ["*"]
  }
  statement {
    sid = "ecspassrole"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      "arn:aws:iam::*:role/ecs-task-*"
    ]
  }
  statement {
    sid = "AmiBuilder"
    actions = [
      "ec2:CopyImage",
      "ec2:CreateImage",
      "ec2:CreateSnapshot",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:DescribeImages",
      "ec2:DescribeImageAttribute",
      "ec2:DescribeFastLaunchImages",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeSecurityGroups",
      "ec2:DeleteSecurityGroup",
      "ec2:CreateSecurityGroup",
      "ec2:DescribeSnapshots",
      "ec2:DescribeSubnets",
      "ec2:DescribeVolumes",
      "ec2:DescribeTags",
      "ec2:RegisterImage",
      "ec2:RunInstances",
      "ec2:GetPasswordData",
      "ec2:CreateKeyPair",
      "ec2:DeleteKeyPair",
      "iam:GetInstanceProfile",
      "iam:PassRole",
      "ssm:GetCommandInvocation",
      "ssm:StartSession",
      "ssm:SendCommand",
      "ssm:GetConnectionStatus",
      "ssm:ResumeSession",
      "ssm:ListCommands",
      "ssm:DescribeSessions",
      "ssm:TerminateSession",
      "ssm:DescribeInstanceInformation",
      "ssm:ListDocuments",
      "ssm:ListCommandInvocations",
      "ssm:DescribeInstanceProperties"
    ]
    resources = ["*"]
  }
  statement {
    sid = "AmiBuilderSelected"
    actions = [
      "ec2:AttachVolume",
      "ec2:DeleteSnapshot",
      "ec2:DeleteVolume",
      "ec2:DeregisterImage",
      "ec2:DetachVolume",
      "ec2:ModifyImageAttribute",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifySnapshotAttribute",
      "ec2:StopInstances",
      "ec2:TerminateInstances"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/Creator"
      values   = ["Packer"]
    }
  }
}

resource "aws_iam_policy" "ecs_default" {
  count  = contains(var.policy_sets, "ECS_DEFAULT") ? 1 : 0
  name   = "ci-deploy-ecs-default"
  policy = data.aws_iam_policy_document.policy_set_ecs_default[0].json
}

resource "aws_iam_role_policy_attachment" "policy_set_ecs_default" {
  count      = contains(var.policy_sets, "ECS_DEFAULT") ? 1 : 0
  role       = aws_iam_role.ci_deploy_access.name
  policy_arn = aws_iam_policy.ecs_default[0].arn
}
