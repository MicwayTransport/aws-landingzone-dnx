# This file calls the reusable KMS submodule and wires it to other resources.

module "app_kms_keys" {
  source = "./modules/kms"

  # This constructs the input variable for the KMS submodule.
  # It is placed directly inside the module block to ensure it is evaluated
  # only after the 'depends_on' is satisfied.
  app_kms_keys = [
    for key in var.kms_keys : {
      # Pass-through attributes
      name        = key.name
      description = key.description
      tags        = key.tags

      # This is the wiring logic. It translates the role name into a full ARN.
      allowed_iam_principals = [
        # This uses the 'irsa_role_arns' output that you confirmed exists.
        for role_name in key.allowed_iam_principal_names : module.eks[0].irsa_role_arns[role_name]
      ]
    }
  ]

  # This explicitly tells Terraform to fully create module.eks
  # BEFORE attempting to evaluate this module block.
  depends_on = [
    module.eks
  ]
}