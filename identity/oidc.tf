module "bitbucket_oidc" {
  count  = try(var.oidc.enabled, false) && try(var.oidc.vendor, "") == "bitbucket" ? 1 : 0
  source = "git::https://github.com/DNXLabs/terraform-aws-vcs-oidc.git?ref=0.1.0"

  identity_provider_url = "https://api.bitbucket.org/2.0/workspaces/${try(var.oidc.workspace, "")}/pipelines-config/identity/oidc"
  audiences = [
    "ari:cloud:bitbucket::workspace/${try(var.oidc.workspace_uuid, "")}"
  ]

  roles = [for role in var.oidc.roles :
    {
      name = role.name

      assume_roles = formatlist("arn:aws:iam::*:role/%s", compact([try(role.assume_role, "")]))
      assume_policies = length(try(role.policy_arns, [])) == 0 ? [
        for name, arn in module.ci_deploy_access[0].policies : arn if contains(try(role.policy_sets, []), name)
      ] : try(role.policy_arns, [])

      conditions = [
        {
          test     = "ForAnyValue:StringLike"
          variable = "api.bitbucket.org/2.0/workspaces/${try(var.oidc.workspace, "")}/pipelines-config/identity/oidc:sub"
          # {REPOSITORY_UUID}*:{ENVIRONMENT_UUID}:* or {REPOSITORY_UUID}:*
          # Max of ~30 conditions.
          values = "*:*"
          values = formatlist("%s:*", role.all_repos ? ["*"] : try(role.repos, []))
        },
        # { # Limit only assumes requests coming from Bitbucket Pipelines IP to assume the role.
        #   test     = "IpAddress"
        #   variable = "aws:SourceIp"
        #   values = [
        #     "34.199.54.113/32",
        #     "34.232.25.90/32",
        #     "34.232.119.183/32",
        #     "34.236.25.177/32",
        #     "35.171.175.212/32",
        #     "52.54.90.98/32",
        #     "52.202.195.162/32",
        #     "52.203.14.55/32",
        #     "52.204.96.37/32",
        #     "34.218.156.209/32",
        #     "34.218.168.212/32",
        #     "52.41.219.63/32",
        #     "35.155.178.254/32",
        #     "35.160.177.10/32",
        #     "34.216.18.129/32"
        #   ]
        # }
      ]
  }]
}

output "bitbucket_oidc_roles" {
  value = try(module.bitbucket_oidc[*].roles, {})
}

module "github_oidc" {
  count  = try(var.oidc.enabled, false) && try(var.oidc.vendor, "") == "github" ? 1 : 0
  source = "git::https://github.com/DNXLabs/terraform-aws-vcs-oidc.git?ref=0.1.0"

  identity_provider_url = "https://token.actions.githubusercontent.com"
  audiences             = ["sts.amazonaws.com"]

  roles = [for role in var.oidc.roles :
    {
      name         = role.name
      assume_roles = formatlist("arn:aws:iam::*:role/%s", compact([try(role.assume_role, "")]))
      assume_policies = length(try(role.policy_arns, [])) == 0 ? [
        for name, arn in module.ci_deploy_access[0].policies : arn if contains(try(role.policy_sets, []), name)
      ] : try(role.policy_arns, [])

      conditions = [
        {
          test     = "ForAnyValue:StringLike"
          variable = "token.actions.githubusercontent.com:sub"
          values   = formatlist("repo:${try(var.oidc.org, "")}/%s:*", role.all_repos ? ["*"] : try(role.repos, []))
        }
      ]
  }]
}

output "github_oidc_roles" {
  value = try(module.github_oidc[*].roles, {})
}

module "gitlab_oidc" {
  count  = try(var.oidc.enabled, false) && try(var.oidc.vendor, "") == "gitlab" ? 1 : 0
  source = "git::https://github.com/DNXLabs/terraform-aws-vcs-oidc.git?ref=0.1.0"

  identity_provider_url = "https://gitlab.com"
  audiences             = ["https://gitlab.com"]

  roles = [for role in var.oidc.roles :
    {
      name = role.name

      assume_roles = formatlist("arn:aws:iam::*:role/%s", compact([try(role.assume_role, "")]))
      assume_policies = length(try(role.policy_arns, [])) == 0 ? [
        for name, arn in module.ci_deploy_access[0].policies : arn if contains(try(role.policy_sets, []), name)
      ] : try(role.policy_arns, [])

      conditions = [
        {
          test     = "StringLike"
          variable = "gitlab.com:sub"
          values   = formatlist("project_path:${try(var.oidc.org, "")}/%s:ref_type:branch:ref:*", role.all_repos ? ["*"] : try(role.repos, []))
        }
      ]
  }]
}

output "gitlab_oidc_roles" {
  value = try(module.gitlab_oidc[*].roles, {})
}
