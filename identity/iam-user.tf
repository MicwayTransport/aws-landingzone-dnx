module "aws_iam_user" {
  for_each   = { for iam in try(var.iam_users, []) : iam.name => iam if try(iam.enabled, false) == true }
  source     = "./modules/iam-user"
  name       = each.value.name
  iam_policy = each.value.iam_policy
}
