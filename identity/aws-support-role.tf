# Role that needs to be created when AWS needs access (to the support team)
module "aws_support_role" {
  count  = try(var.aws_support_role.enabled, false) ? 1 : 0
  source = "./modules/aws-support-access-role"
}
