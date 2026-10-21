locals {
  alb_arn_list = can(var.wafv2[0]) ? [module.ecs_cluster[var.wafv2[0].cluster_name[0]].alb_arn[0]] : []
}

module "terraform_aws_wafv2_global" {
  source = "./modules/waf-webaclv2"

  for_each               = { for waf in try(var.wafv2, []) : waf.name => waf }
  enabled                = try(each.value.enabled, false)
  name_prefix            = each.value.name
  allow_default_action   = try(each.value.allow_default_action, true)
  scope                  = try(each.value.scope, "REGIONAL")
  create_alb_association = try(each.value.enabled, false)
  alb_arn_list           = local.alb_arn_list
  rules                  = try(each.value.rules, [])
  #alb_arn                = try(var.waf.alb_arn, "") #aws_lb.loadbalancer.*.arn[0]

  visibility_config = {
    cloudwatch_metrics_enabled = false
    metric_name                = "${each.value.name}-waf-main-metrics"
    sampled_requests_enabled   = false
  }

  tags = {
    "Name"        = "${each.value.name}"
    "Environment" = try(var.account_name, "")
  }

}

