resource "aws_organizations_organization" "master" {
  count                         = try(var.detective.enabled, false) && try(var.detective.role, false) == "master" ? 1 : 0
  aws_service_access_principals = ["detective.amazonaws.com"]
  feature_set                   = "ALL"
}

resource "aws_detective_organization_admin_account" "master" {
  count      = try(var.detective.enabled, false) && try(var.detective.role, false) == "master" ? 1 : 0
  depends_on = [aws_organizations_organization.master]

  account_id = var.aws_account_id
}

resource "aws_detective_graph" "master" {
  count = try(var.detective.enabled, false) && try(var.detective.role, false) == "master" ? 1 : 0
  tags = {
    Name = "detective-graph-${terraform.workspace}"
  }
}
## invite member
resource "aws_detective_member" "member" {
  for_each      = { for member in try(var.organization.members, []) : member.account_id => member if try(var.detective.enabled, false) }
  account_id    = each.value.account_id
  email_address = each.value.email
  graph_arn     = aws_detective_graph.master[0].graph_arn
}

output "admin_graph_arn" {
  value = try(var.detective.admin_graph_arn, "")
}

