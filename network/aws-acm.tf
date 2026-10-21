module "acm_certificate" {
  for_each = {
    for certificate in var.acm.certificates : certificate.name => certificate
    if try(certificate.local, true) == true
  }
  source = "git::https://github.com/DNXLabs/terraform-aws-acm-certificate?ref=0.3.1"

  domain_names             = each.value.domain_names
  hosted_zone_id           = can(each.value.hosted_zone) ? aws_route53_zone.default[each.value.hosted_zone].zone_id : null
  create_validation_record = can(each.value.hosted_zone) ? true : false
}

module "acm_certificate_global" {
  for_each = {
    for certificate in var.acm.certificates : certificate.name => certificate
    if try(certificate.global, false) == true
  }
  providers = { aws = aws.us-east-1 }
  source    = "git::https://github.com/DNXLabs/terraform-aws-acm-certificate?ref=0.3.1"

  domain_names   = each.value.domain_names
  hosted_zone_id = can(each.value.hosted_zone) ? aws_route53_zone.default[each.value.hosted_zone].zone_id : ""
}

output "acm_certificate" {
  value = element(module.acm_certificate[*], 0)
}

output "acm_certificate_global" {
  value = element(module.acm_certificate_global[*], 0)
}
