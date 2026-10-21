resource "aws_iam_role_policy_attachment" "policy_set_admin" {
  count      = contains(var.policy_sets, "ADMIN") ? 1 : 0
  role       = aws_iam_role.ci_deploy_access.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
