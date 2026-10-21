locals {
  route_table_ids = concat(
    try(var.site_to_site_vpn.route_secure_subnets, false) ? [module.network[0].secure_route_table_id] : [],
    try(var.site_to_site_vpn.route_private_subnets, false) ? module.network[0].private_route_table_id : [],
    try(var.site_to_site_vpn.route_public_subnets, false) ? [module.network[0].public_route_table_id] : [],
  )
}

module "site_to_site_vpn" {
  source                                    = "git::https://github.com/DNXLabs/terraform-aws-vpn-connection.git?ref=0.3.0"
  count                                     = try(var.site_to_site_vpn.enabled, false) ? 1 : 0
  name                                      = try(var.site_to_site_vpn.name, null)
  vpc_id                                    = module.network[0].vpc_id
  customer_gateway_bgp_asn                  = try(var.site_to_site_vpn.bgp_asn, null)
  customer_gateway_ip_address               = try(var.site_to_site_vpn.ip_address, null)
  transit_gateway_id                        = try(module.transit_gateway[0].transit_gateway_id[0], null)
  vpn_connection_static_routes_only         = try(var.site_to_site_vpn.static_only, false) ? "true" : "false"
  vpn_connection_static_routes_destinations = try(var.site_to_site_vpn.static_route_destinations, [])
  route_table_ids                           = local.route_table_ids
  vpn_connection_local_ipv4_network_cidr    = try(var.site_to_site_vpn.local_cidr, null)
  vpn_connection_remote_ipv4_network_cidr   = try(var.site_to_site_vpn.remote_cidr, null)

  vpn_connection_tunnel1_ike_versions                 = ["ikev2"]                            # ikev1 | ikev2
  vpn_connection_tunnel1_phase1_encryption_algorithms = ["AES256-GCM-16", "AES256"]          # AES128 | AES256 | AES128-GCM-16 | AES256-GCM-16
  vpn_connection_tunnel1_phase1_integrity_algorithms  = ["SHA2-512", "SHA2-384", "SHA2-256"] # SHA1 | SHA2-256 | SHA2-384 | SHA2-512
  vpn_connection_tunnel1_phase1_dh_group_numbers      = [21, 20, 19]                         # 2 | 5 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24
  vpn_connection_tunnel1_phase2_dh_group_numbers      = [21, 20, 19]                         # 2 | 5 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24

  vpn_connection_tunnel2_ike_versions                 = ["ikev2"]                            # ikev1 | ikev2 
  vpn_connection_tunnel2_phase1_encryption_algorithms = ["AES256-GCM-16", "AES256"]          # AES128 | AES256 | AES128-GCM-16 | AES256-GCM-16
  vpn_connection_tunnel2_phase1_integrity_algorithms  = ["SHA2-512", "SHA2-384", "SHA2-256"] # SHA1 | SHA2-256 | SHA2-384 | SHA2-512
  vpn_connection_tunnel2_phase1_dh_group_numbers      = [21, 20, 19]                         # 2 | 5 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24
  vpn_connection_tunnel2_phase2_dh_group_numbers      = [21, 20, 19]                         # 2 | 5 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24
}
