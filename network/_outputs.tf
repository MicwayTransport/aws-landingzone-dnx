resource "local_file" "outputs" {
  content = jsonencode({
    "domain" : { for domain, zone in aws_route53_zone.default : domain => zone }
    "acm_certificate" : element(module.acm_certificate[*], 0)
    "acm_certificate_global" : element(module.acm_certificate_global[*], 0)
    "network" : try(module.network[0], {})
    "peering_requester" : { for peering_name, peering in aws_vpc_peering_connection.requester : peering_name => peering }
    "peering_accepter" : { for peering_name, peering in aws_vpc_peering_connection_accepter.accepter : peering_name => peering }
    "transit_gateway" : try(element(module.transit_gateway[*], 0), {})
  })
  filename = "${path.module}/.outputs/${local.stack_name}-${terraform.workspace}.json"
}

# resource "aws_secretsmanager_secret" "outputs" {
#   name = "outputs-network-${terraform.workspace}"
# }

# resource "aws_secretsmanager_secret_version" "outputs" {
#   secret_id     = aws_secretsmanager_secret.outputs.id
#   secret_string = jsonencode({
#     "domain": { for domain, zone in aws_route53_zone.default : domain => zone }
#     "acm_certificate": element(module.acm_certificate[*], 0)
#     "acm_certificate_global": element(module.acm_certificate_global[*], 0)
#     "network": try(module.network[0], {})
#     "peering_requester": { for peering_name, peering in aws_vpc_peering_connection.requester : peering_name => peering }
#     "peering_accepter": { for peering_name, peering in aws_vpc_peering_connection_accepter.accepter : peering_name => peering }
#   })
# }