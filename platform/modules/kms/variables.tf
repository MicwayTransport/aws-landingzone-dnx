variable "app_kms_keys" {
  description = "A list of application-specific KMS keys to create."
  type = list(object({
    name                   = string
    description            = string
    // This correctly expects a list of final ARNs
    allowed_iam_principals = list(string)
    tags                   = map(string)
  }))
  default = []
}