data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_cloudformation_stack" "baseline" {
  count = var.saml_provider.get_from_baseline_cf_stack ? 1 : 0
  name  = try(var.baseline_cf_stack_name, "identity-baseline")
}
