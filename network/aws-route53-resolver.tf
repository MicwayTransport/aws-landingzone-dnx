resource "aws_security_group" "route53_resolver" {
  count       = length(try(var.route53_resolver.outbound_rules.domains, "")) > 0 ? 1 : 0
  name        = "route53-resolver"
  description = "Allow DNS(53) outbound traffic to resolver"
  vpc_id      = module.network[0].vpc_id

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


resource "aws_route53_resolver_endpoint" "outbound" {
  count     = length(try(var.route53_resolver.outbound_rules.domains, "")) > 0 ? 1 : 0
  name      = "internal-route53-resolver"
  direction = "OUTBOUND"

  security_group_ids = [aws_security_group.route53_resolver[0].id]

  dynamic "ip_address" {
    for_each = module.network[0].private_subnet_ids
    content {
      subnet_id = ip_address.value
    }
  }

}


resource "aws_route53_resolver_rule" "outbound" {
  for_each             = { for domain in try(var.route53_resolver.outbound_rules.domains, []) : domain.name => domain }
  domain_name          = each.value.name
  name                 = replace(each.value.name, ".", "-")
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound[0].id

  dynamic "target_ip" {
    for_each = each.value.targets
    content {
      ip = target_ip.value
    }
  }

  tags = {
    domain = each.value.name
  }
}

resource "aws_route53_resolver_rule_association" "outbound" {
  for_each = { for domain in try(var.route53_resolver.outbound_rules.domains, []) : domain.name => domain }

  resolver_rule_id = aws_route53_resolver_rule.outbound[each.value.name].id
  vpc_id           = module.network[0].vpc_id
}
