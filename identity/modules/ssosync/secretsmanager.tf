locals {
  secrets = {
    SSOSyncGoogleCredentials = var.aws_google_credentials
    SSOSyncGoogleAdminEmail  = var.aws_google_admin_email
    SSOSyncSCIMEndpointUrl   = var.aws_scim_endpoint
    SSOSyncSCIMAccessToken   = var.aws_scim_access_token
  }
}

resource "aws_secretsmanager_secret" "ssosync" {
  for_each = local.secrets
  name     = each.key
}

resource "aws_secretsmanager_secret_version" "ssosync" {
  for_each      = {for k, v in local.secrets : k => v if nonsensitive(v) != null}
  secret_id     = aws_secretsmanager_secret.ssosync[each.key].id
  secret_string = jsonencode(each.value)
}
