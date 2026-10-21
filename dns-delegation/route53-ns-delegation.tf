# =============================================================================
# NS RECORD DELEGATION
# =============================================================================
# Creates NS records in parent zone pointing to child zone nameservers
# This enables DNS delegation from parent to child zones
# 
# Example:
#   Parent: infra.indyrct.com (shared-services)
#   Child:  dev.infra.indyrct.com (dev account)
#   Result: NS records for "dev" in parent zone → child nameservers
# =============================================================================

resource "aws_route53_record" "child_zone_ns" {
  for_each = var.child_zones

  zone_id = var.parent_zone_id
  name    = each.value.subdomain
  type    = "NS"
  ttl     = 172800  # 48 hours - standard for NS records
  
  records = each.value.name_servers
}
