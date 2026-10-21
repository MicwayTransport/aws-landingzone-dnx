resource "aws_vpc_peering_connection" "requester" {
  for_each = { for peering in var.network.peering : peering.name => peering
  if var.network.enabled && peering.mode == "requester" }
  peer_vpc_id   = each.value.vpc_id
  peer_owner_id = each.value.account_id
  vpc_id        = module.network[0].vpc_id
  peer_region   = var.aws_region
}

resource "aws_route" "requester" {
  for_each = { for peering in var.network.peering : peering.name => peering
  if var.network.enabled && peering.mode == "requester" }
  route_table_id            = module.network[0].private_route_table_id[0]
  destination_cidr_block    = each.value.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.requester[each.key].id
}

resource "aws_network_acl_rule" "in_requester_from_accepter" {
  for_each = { for peering in var.network.peering : peering.name => peering
  if var.network.enabled && peering.mode == "requester" }
  network_acl_id = module.network[0].private_nacl_id
  rule_number    = 1000 + index(var.network.peering, each.value)
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = each.value.vpc_cidr
}

resource "aws_network_acl_rule" "out_requester_to_accepter" {
  for_each = { for peering in var.network.peering : peering.name => peering
  if var.network.enabled && peering.mode == "requester" }
  network_acl_id = module.network[0].private_nacl_id
  rule_number    = 1000 + index(var.network.peering, each.value)
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = each.value.vpc_cidr
}

resource "aws_route53_zone_association" "accepter" {
  for_each = { for peering in var.network.peering : peering.name => peering
  if var.network.enabled && peering.mode == "requester" && try(peering.hosted_zone_id, "") != "" }
  zone_id = each.value.hosted_zone_id
  vpc_id  = each.value.vpc_id
}

output "vpc_peering_requester_ids" {
  value = { for peering_name, peering in aws_vpc_peering_connection.requester : peering_name => peering.id }
}
