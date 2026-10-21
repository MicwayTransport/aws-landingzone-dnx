resource "aws_vpc_peering_connection_accepter" "accepter" {
  for_each = { for peering in var.network.peering : peering.name => peering
  if var.network.enabled && peering.mode == "accepter" }

  vpc_peering_connection_id = each.value.requester_peering_id
  auto_accept               = true
}

resource "aws_route" "accepter_private_0" {
  for_each = { for peering in var.network.peering : peering.name => peering
  if var.network.enabled && peering.mode == "accepter" }
  route_table_id            = module.network[0].private_route_table_id[0]
  destination_cidr_block    = each.value.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.accepter[each.key].id
}

resource "aws_route" "accepter_private_1" {
  for_each = { for peering in var.network.peering : peering.name => peering
  if var.network.enabled && peering.mode == "accepter" && length(try(module.network[0].private_route_table_id, [])) == 3 }
  route_table_id            = module.network[0].private_route_table_id[1]
  destination_cidr_block    = each.value.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.accepter[each.key].id
}

resource "aws_route" "accepter_private_2" {
  for_each = { for peering in var.network.peering : peering.name => peering
  if var.network.enabled && peering.mode == "accepter" && length(try(module.network[0].private_route_table_id, "")) == 3 }
  route_table_id            = module.network[0].private_route_table_id[2]
  destination_cidr_block    = each.value.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.accepter[each.key].id
}

# This is considering network is set with `max_az=3` (the default)

resource "aws_route" "accepter_secure" {
  for_each = { for peering in var.network.peering : peering.name => peering
  if var.network.enabled && peering.mode == "accepter" }
  route_table_id            = module.network[0].secure_route_table_id
  destination_cidr_block    = each.value.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.accepter[each.key].id
}

resource "aws_network_acl_rule" "in_accepter_private_from_requester" {
  for_each = { for peering in var.network.peering : peering.name => peering
  if var.network.enabled && peering.mode == "accepter" }
  network_acl_id = module.network[0].private_nacl_id
  rule_number    = 1000 + index(var.network.peering, each.value)
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = each.value.vpc_cidr
}

resource "aws_network_acl_rule" "out_accepter_private_to_requester" {
  for_each = { for peering in var.network.peering : peering.name => peering
  if var.network.enabled && peering.mode == "accepter" }
  network_acl_id = module.network[0].private_nacl_id
  rule_number    = 1000 + index(var.network.peering, each.value)
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = each.value.vpc_cidr
}

resource "aws_network_acl_rule" "in_accepter_secure_from_requester" {
  for_each = { for peering in var.network.peering : peering.name => peering
  if var.network.enabled && peering.mode == "accepter" }
  network_acl_id = module.network[0].secure_nacl_id
  rule_number    = 1000 + index(var.network.peering, each.value)
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = each.value.vpc_cidr
}

resource "aws_network_acl_rule" "out_accepter_secure_to_requester" {
  for_each = { for peering in var.network.peering : peering.name => peering
  if var.network.enabled && peering.mode == "accepter" }
  network_acl_id = module.network[0].secure_nacl_id
  rule_number    = 1000 + index(var.network.peering, each.value)
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = each.value.vpc_cidr
}
