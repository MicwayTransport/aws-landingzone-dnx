output "delegated_zones" {
  description = "Map of delegated child zones and their NS records"
  value = {
    for key, record in aws_route53_record.child_zone_ns : key => {
      fqdn         = record.fqdn
      name_servers = record.records
      ttl          = record.ttl
    }
  }
}

output "parent_zone_id" {
  description = "Parent zone ID where NS records were created"
  value       = var.parent_zone_id
}

output "parent_zone_name" {
  description = "Parent zone name"
  value       = var.parent_zone_name
}
