module "vpn" {
  source                           = "git::https://github.com/DNXLabs/terraform-aws-client-vpn.git?ref=0.11.0"
  count                            = try(var.vpn.enabled, false) ? 1 : 0
  name                             = try(var.vpn.name, "")
  cidr                             = try(var.vpn.cidr, "")
  subnet_ids                       = [module.network[0].private_subnet_ids[0]]
  vpc_id                           = module.network[0].vpc_id
  organization_name                = var.org_name
  tags                             = {}
  logs_retention                   = try(var.vpn.logs_retention, 365)
  authentication_type              = "federated-authentication"
  authentication_saml_provider_arn = try(var.vpn.saml_provider_arn, "")
  split_tunnel                     = try(var.vpn.split_tunnel, true)
  allowed_cidr_ranges              = length(try(var.vpn.allowed_access_groups, [])) > 0 ? [module.network[0].cidr_block] : []
  allowed_access_groups            = try(var.vpn.allowed_access_groups, [])
}

output "vpn_sg_id" {
  value = try(module.vpn[0].security_group_id, "")
}
