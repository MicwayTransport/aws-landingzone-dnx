# #https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Cross-Account-Cross-Region.html#enable-cross-account-cross-Region

# locals {
#   #   policy_arns = [
#   #     data.aws_iam_policy.CloudWatchReadOnlyAccess.arn,
#   #     data.aws_iam_policy.CloudWatchAutomaticDashboardsAccess.arn,
#   #     data.aws_iam_policy.AWSXrayReadOnlyAccess
#   #   ]
#   names = [
#     "CloudWatchReadOnlyAccess",
#     "CloudWatchAutomaticDashboardsAccess",
#     "AWSXrayReadOnlyAccess"
#   ]

#   policy = {
#     "Version" : "2012-10-17",
#     "Statement" : [
#       {
#         "Effect" : "Allow",
#         "Principal" : {
#           "AWS" : try(var.cloudwatch.share_aws_account_ids, [data.aws_caller_identity.current.id])
#         },
#         "Action" : "sts:AssumeRole"
#         "Condition": {
#             "StringEquals": {
#                 "aws:PrincipalOrgID": data.aws_organizations_organization.current.id
#         }
#       }
#       }
#     ]
#   }

# }

# data "aws_iam_policy" "policy" {
#   for_each = toset(local.names)
#   name     = each.value
# }

# resource "aws_iam_role" "aws-cloudwatch-metrics-role" {
#   name = "CloudWatch-CrossAccountSharingRole"
#   assume_role_policy = jsonencode(local.policy)
# }

# resource "aws_iam_role_policy_attachment" "policy" {
#   for_each = toset(local.names)
#   #   policy_arn = each.value

#   policy_arn = data.aws_iam_policy.policy[each.key].arn
#   role       = aws_iam_role.aws-cloudwatch-metrics-role.name
# }
