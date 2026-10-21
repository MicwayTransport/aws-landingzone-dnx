
resource "aws_iam_policy" "serverless_stack" {
  count = contains(var.policy_sets, "SERVERLESS_STACK") ? 1 : 0
  name  = "ci-deploy-serverless-stack"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DelegateToCloudfrontRole"
        Effect   = "Allow"
        Action   = ["cloudfront:*"]
        Resource = ["*"]
      },
      {
        Sid      = "DelegateToAppSyncRole"
        Effect   = "Allow"
        Action   = ["appsync:*"]
        Resource = ["*"]
      },
      {
        Sid      = "DelegateToLambdaRole"
        Effect   = "Allow"
        Action   = ["lambda:*"]
        Resource = ["arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:*"]
      },
      {
        Sid      = "DevelopEventSourceMappings",
        Effect   = "Allow", 
        Action   = [
          "lambda:DeleteEventSourceMapping",
          "lambda:UpdateEventSourceMapping",
          "lambda:CreateEventSourceMapping"
        ],
        Resource = "*",
        Condition = {
          StringLike = {
            "lambda:FunctionArn" = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:*"
          }
        }
      },
      {
        Sid      = "DelegateToApigatewayRole"
        Effect   = "Allow"
        Action   = ["apigateway:*"]
        Resource = [
          "arn:aws:apigateway:${data.aws_region.current.name}::/apis/*",
          "arn:aws:apigateway:${data.aws_region.current.name}::/domainnames/*",
          "arn:aws:apigateway:${data.aws_region.current.name}::/restapis/*"
        ]
      },
      {
        Sid      = "DelegateToCloudFormationRole"
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = ["${aws_iam_role.cloudformation_deploy_custom[0].arn}"]
      },
      {
        Sid      = "ManagedIam"
        Effect   = "Allow"
        Action   = ["iam:*"]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.serverless_deploy_role_name}*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.serverless_app_prefix}*",
        ]
      },
      {
        Sid      = "ManagedStsAssume"
        Effect   = "Allow"
        Action   = ["sts:AssumeRole"]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.serverless_deploy_role_name}*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.serverless_app_prefix}*",
        ]
      },
      {
        Sid      = "GetRole"
        Effect   = "Allow"
        Action   = ["iam:GetRole"]
        Resource = ["*"]
      },
      {
        Sid      = "ManagedSecurityGroup"
        Effect   = "Allow"
        Action   = [
          "ec2:CreateSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:DeleteSecurityGroup",
          "ec2:DescribeSecurityGroups",
          "ec2:CreateTags",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:Describe*",
          "ec2:AttachNetworkInterface",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface",
          "ec2:DetachNetworkInterface",
          "ec2:ModifyNetworkInterfaceAttribute",
          "ec2:ResetNetworkInterfaceAttribute",
          "ec2:CreateNetworkInterfacePermission",
          "ec2:DeleteNetworkInterfacePermission",
        ]
        Resource = ["*"]
      },
      {
        Sid    = "ManageSqs"
        Effect = "Allow"
        Action = [
          "sqs:*",
        ]
        Resource = ["arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.serverless_app_prefix}*"]
      },
      {
        Sid    = "ManageEventBridge"
        Effect = "Allow"
        Action = [
          "events:*",
        ]
        Resource = [
          "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:event-bus/${var.serverless_app_prefix}-*",
          "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rule/${var.serverless_app_prefix}*/*",
        ]
      },
      {
        Sid      = "ValidateTemplate"
        Effect   = "Allow"
        Action   = ["cloudformation:ValidateTemplate"]
        Resource = ["*"]
      },
      {
        Sid    = "ExecuteCloudFormation"
        Effect = "Allow"
        Action = [
          "cloudformation:CreateChangeSet",
          "cloudformation:CreateStack",
          "cloudformation:DeleteChangeSet",
          "cloudformation:DeleteStack",
          "cloudformation:DescribeChangeSet",
          "cloudformation:DescribeStackEvents",
          "cloudformation:DescribeStackResource",
          "cloudformation:DescribeStackResources",
          "cloudformation:DescribeStacks",
          "cloudformation:ExecuteChangeSet",
          "cloudformation:ListStackResources",
          "cloudformation:SetStackPolicy",
          "cloudformation:UpdateStack",
          "cloudformation:UpdateTerminationProtection",
          "cloudformation:GetTemplate",
        ]
        Resource = [
          "arn:aws:cloudformation:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stack/${var.serverless_app_prefix}*/*",
          "arn:aws:cloudformation:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stack/CDKToolkit/*",
        ]
      },
      {
        Sid    = "ReadLambda"
        Effect = "Allow"
        Action = [
          "lambda:Get*",
          "lambda:List*",
        ]
        Resource = ["*"]
      },
      {
        Sid    = "ManageDeploymentBucket"
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:GetBucketPolicy",
          "s3:PutBucketPolicy",
          "s3:DeleteBucketPolicy",
          "s3:PutBucketAcl",
          "s3:GetEncryptionConfiguration",
          "s3:PutEncryptionConfiguration",
          "s3:GetBucketLocation",
          "s3:PutBucketTagging",
        ]
        Resource = [
          "arn:aws:s3:::${var.serverless_app_prefix}*",
          "arn:aws:s3:::cdk-*",
          "arn:aws:s3:::*",
        ]
      },
      {
        Sid      = "ListS3"
        Effect   = "Allow"
        Action   = ["s3:List*"]
        Resource = ["*"]
      },
      {
        Sid      = "SSM"
        Effect   = "Allow"
        Action   = ["ssm:*"]
        Resource = ["*"]
      },
      {
        Sid      = "Route53"
        Effect   = "Allow"
        Action   = ["route53:ListHostedZonesByName"]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "policy_set_serverless_stack" {
  count = contains(var.policy_sets, "SERVERLESS_STACK") ? 1 : 0
  role       = aws_iam_role.ci_deploy_access.name
  policy_arn = aws_iam_policy.serverless_stack[0].arn
}