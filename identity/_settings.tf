locals {
  # Get SAML Provider ARN from baseline CF stack
  # or from an Existing ARN passed in the config
  # saml_provider_arn = (
  #   local.workspace.saml_provider.get_from_baseline_cf_stack
  #   ) ? (
  #   data.aws_cloudformation_stack.baseline[0].outputs.IAMIdentityProviderArn
  #   ) : (
  #   local.workspace.saml_provider.existing_arn
  # )
}

locals {
  stack_name = "identity"
}
