locals {
  dump_record_files     = { for zone in var.domain.zones : zone.route53_domain => try(yamldecode(file("${try(var.domain.records_path, "./route53/")}/${zone.route53_domain}/${try(var.domain.records_file, "main.yaml")}")), {}) }
  domain_records_config = { for zone in var.domain.zones : zone.route53_domain => lookup(lookup(local.dump_record_files, zone.route53_domain, []), "records", []) }
  records_compiled = [
    for zone in var.domain.zones : {
      for record in try(local.domain_records_config[zone.route53_domain], []) : "${record.name}:${record.type}" => merge(record, { route53_domain = zone.route53_domain })
    }
  ]
  records_compiled_merged = merge(local.records_compiled...)
}

resource "aws_route53_record" "bydomain" {
  for_each = {
    for item in local.records_compiled_merged : "${item.name}:${item.type}" => item
    if length(try(item.records, [])) > 0 || length(try(item.alias, {})) > 0
  }
  zone_id = aws_route53_zone.default[each.value.route53_domain].zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = length(try(each.value.alias, [])) > 0 ? null : try(each.value.ttl, 300)
  records = try(each.value.records, null)

  dynamic "alias" {
    for_each = length(try(each.value.alias, [])) > 0 ? [each.value.alias] : []

    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }
}


resource "aws_route53_zone" "default" {
  for_each = {
    for zone in var.domain.zones : zone.route53_domain => zone
    if var.domain.enabled
  }
  name = each.value.route53_domain

  dynamic "vpc" {
    for_each = each.value.private ? [true] : []
    content {
      vpc_id = module.network[0].vpc_id
    }
  }
}

resource "aws_route53_traffic_policy" "bydomain" {
  for_each = {
    for item in local.records_compiled_merged : "${item.name}:${item.type}" => item
    if length(try(item.traffic_policy, [])) > 0
  }

  name     = each.value.traffic_policy.name
  comment  = try(each.value.traffic_policy.comment, null)
  document = try(each.value.traffic_policy.document, null)
}

resource "aws_route53_traffic_policy_instance" "bydomain" {
  for_each = {
    for item in local.records_compiled_merged : "${item.name}:${item.type}" => item
    if length(try(item.traffic_policy, [])) > 0
  }

  name                   = each.value.name
  traffic_policy_id      = aws_route53_traffic_policy.bydomain["${each.value.name}:${each.value.type}"].id
  traffic_policy_version = 1
  hosted_zone_id         = aws_route53_zone.default[each.value.route53_domain].zone_id
  ttl                    = 60
}

output "route53_name_servers" {
  value = { for domain, zone in aws_route53_zone.default : domain => zone.name_servers }
}

output "route53_hosted_zone_ids" {
  value = { for domain, zone in aws_route53_zone.default : domain => zone.zone_id }
}
