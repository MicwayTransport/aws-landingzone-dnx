data "aws_iam_policy_document" "policy_set_ecs_advanced" {
  count = contains(var.policy_sets, "ECS_ADVANCED") ? 1 : 0
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
      "ecr:*"
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
    sid = "logs"
    actions = [
      "logs:*"
    ]
    resources = ["*"]
  }
  statement {
    sid = "iam"
    actions = [
      "iam:CreateInstanceProfile",
      "iam:list*",
      "iam:PassRole",
      "iam:Get*",
      "iam:CreateRole",
      "iam:AddRoleToInstanceProfile",
      "sts:*"
    ]
    resources = ["*"]
  }
  statement {
    sid = "iamattach"
    actions = [
      "iam:AttachRolePolicy"
    ]  
    resources = ["*"]
    condition {
      test     = "ArnNotLike"
      variable = "iam:PolicyARN"

      values = [
        "arn:aws:iam::aws:policy/*Administrator",
        "arn:aws:iam::aws:policy/Administrator*",
        "arn:aws:iam::aws:policy/job-function/Administrator*",
        "arn:aws:iam::aws:policy/job-function/*Administrator"
      ]
    }
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
}

resource "aws_iam_policy" "ecs_advanced" {
  count = contains(var.policy_sets, "ECS_ADVANCED") ? 1 : 0
  name   = "ci-deploy-ecs-advanced"
  policy = data.aws_iam_policy_document.policy_set_ecs_advanced[0].json
}

resource "aws_iam_role_policy_attachment" "policy_set_ecs_advanced" {
  count      = contains(var.policy_sets, "ECS_ADVANCED") ? 1 : 0
  role       = aws_iam_role.ci_deploy_access.name
  policy_arn = aws_iam_policy.ecs_advanced[0].arn
}
