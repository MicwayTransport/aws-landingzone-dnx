# module "ecs_app_front" {
#   for_each   = { for app in try(var.ecs.apps, []) : app.name => app if try(app.cloudfront_enable, false) == true }
#   source     = "git::https://github.com/DNXLabs/terraform-aws-ecs-app-front.git?ref=1.15.0"
#   providers  = { aws = aws.us-east-1 }
#   depends_on = [module.ecs_cluster]

#   certificate_arn           = try(each.value.certificate_arn_us, "")
#   cluster_name              = each.value.cluster_name
#   alb_dns_name              = element(module.ecs_cluster[each.value.cluster_name].alb_dns_name, 0)
#   hosted_zone               = each.value.hosted_zone
#   hostname_create           = try(each.value.hostname_create, false)
#   hostnames                 = try(each.value.hostnames, [])
#   name                      = each.value.name
#   alb_cloudfront_key        = "${each.value.cluster_name}-${each.value.name}"
#   waf_cloudfront_enable     = try(each.value.waf_cloudfront_enable, false)
#   wafv2_managed_rule_groups = try(each.value.wafv2_managed_rule_groups, [])
#   wafv2_rate_limit_rule     = try(each.value.wafv2_rate_limit_rule, 0)

#   dynamic_custom_origin_config = try(each.value.extra_origin, []) != [] ? (
#     [{
#       s3                       = try(each.value.extra_origin.s3_type, false)
#       origin_id                = try(each.value.extra_origin.origin_id, null)
#       domain_name              = try(each.value.extra_origin.domain_name, null)
#       origin_path              = try(each.value.extra_origin.origin_path, null)
#       http_port                = try(each.value.extra_origin.http_port, null)
#       https_port               = try(each.value.extra_origin.https_port, null)
#       origin_protocol_policy   = try(each.value.extra_origin.origin_protocol_policy, null)
#       origin_read_timeout      = try(each.value.extra_origin.origin_read_timeout, null)
#       origin_keepalive_timeout = try(each.value.extra_origin.origin_keepalive_timeout, null)

#   }]) : []

# }
