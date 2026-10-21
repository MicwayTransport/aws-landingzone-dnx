module "network" {
  count  = var.network.enabled ? 1 : 0
  source = "git::https://github.com/DNXLabs/terraform-aws-network.git?ref=2.4.0"

  name_suffix  = try(var.network.name_suffix, "")
  name_pattern = try(var.network.name_pattern, "default")

  max_az         = try(max(1, var.network.max_az), 3)
  newbits        = var.network.vpc_newbits
  vpc_cidr       = var.network.vpc_cidr
  name           = var.network.name
  nat            = try(var.network.nat, true)
  multi_nat      = var.network.multi_nat
  transit_subnet = false
  vpc_flow_logs  = try(var.network.vpc_flow_logs, true)
  vpc_cidr_summ  = try(var.network.vpc_cidr_summ, "/0")

  kubernetes_clusters        = try(var.network.kubernetes_clusters, [])
  kubernetes_clusters_secure = try(var.network.kubernetes_clusters_secure, [])
  kubernetes_clusters_type   = try(var.network.kubernetes_clusters_type, "shared")

  public_netnum_offset  = try(var.network.public_netnum_offset, 0)
  private_netnum_offset = try(var.network.private_netnum_offset, 5)
  secure_netnum_offset  = try(var.network.secure_netnum_offset, 10)

  public_nacl_inbound_tcp_ports  = try(var.network.public_nacl_inbound_tcp_ports, ["80", "443", "22", "1194"])
  public_nacl_outbound_tcp_ports = try(var.network.public_nacl_outbound_tcp_ports, ["0"])

  public_nacl_inbound_udp_ports  = try(var.network.public_nacl_inbound_udp_ports, [])
  public_nacl_outbound_udp_ports = try(var.network.public_nacl_outbound_udp_ports, ["0"])

  # private_nacl_inbound_tcp_ports = try(var.network.private_nacl_inbound_tcp_ports, [0])
  # private_nacl_inbound_udp_ports = try(var.network.private_nacl_inbound_udp_ports, [0])

  # secure_nacl_inbound_tcp_ports = try(var.network.secure_nacl_inbound_tcp_ports, [0])
  # secure_nacl_inbound_udp_ports = try(var.network.secure_nacl_inbound_udp_ports, [0])

  public_nacl_icmp              = true
  vpc_endpoints                 = var.network.vpc_endpoints
  vpc_endpoint_dynamodb_gateway = try(var.network.vpc_endpoint_dynamodb_gateway, false)
  vpc_endpoint_s3_gateway       = try(var.network.vpc_endpoint_s3_gateway, true)

  tags = {
    "TerraformWorkspace" = terraform.workspace
  }

}

output "network" {
  value = try(module.network[0], {})
}

