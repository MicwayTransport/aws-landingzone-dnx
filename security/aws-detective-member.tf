
resource "aws_detective_invitation_accepter" "member" {
  count     = try(var.detective.enabled, false) && try(var.detective.role, false) == "member" ? 1 : 0
  graph_arn = try(var.detective.admin_graph_arn, "")
}
