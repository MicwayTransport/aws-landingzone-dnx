module "transit_gateway" {
  count  = var.transit_gateway.enabled || var.transit_gateway.attachment.enabled ? 1 : 0
  source = "git::https://github.com/DNXLabs/terraform-aws-transit-gateway.git?ref=1.13.0"

  name                       = var.org_name
  account_name               = var.account_name
  transit_gateway_account_id = var.transit_gateway.attachment.transit_gateway_account_id
  allowed_prefixes           = try(var.transit_gateway.allowed_prefixes, [])
  dns_support                = try(var.transit_gateway.dns_support, "enable")
  attachment                 = try(var.transit_gateway.attachment.enabled, false)
  transit_gateway_enabled    = try(var.transit_gateway.enabled, false)
  vpc_id                     = module.network[0].vpc_id
  subnet_ids                 = module.network[0].private_subnet_ids
  private_route_table_id     = module.network[0].private_route_table_id[0]
  public_route_table_id      = module.network[0].public_route_table_id
  secure_route_table_id      = module.network[0].secure_route_table_id
  private_network_acl_id     = module.network[0].private_nacl_id
  public_network_acl_id      = module.network[0].public_nacl_id
  secure_network_acl_id      = module.network[0].secure_nacl_id
  dx_connection              = try(var.transit_gateway.dx_connection, [])
  direct_connect_gateway_asn = try(var.transit_gateway.direct_connect_gateway_asn, "64512")
  transit_gateway_asn        = try(var.transit_gateway.transit_gateway_asn, "64513")
  public_route               = try(var.transit_gateway.attachment.public_route, [])
  private_route              = try(var.transit_gateway.attachment.private_route, [])
  secure_route               = try(var.transit_gateway.attachment.secure_route, [])
}
