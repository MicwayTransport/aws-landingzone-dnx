resource "aws_secretsmanager_secret" "secrets_manager" {
  for_each = { for secrets in try(var.secrets_manager.secrets, []) : secrets.name => secrets }
  name     = each.value.name
}
