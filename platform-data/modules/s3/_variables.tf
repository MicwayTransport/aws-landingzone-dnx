variable "name" {
  type = string
}
variable "log_bucket" {
  type    = string
  default = ""
}
variable "environment" {
  type    = string
  default = "default"
}

variable "kms_key_arn" {
  default = ""
  type    = string
}
variable "versioning" {
  type    = bool
  default = false
}
variable "mfa_delete" {
  type    = bool
  default = false
}

variable "sse_algorithm" {
  default = "aws:kms"
  type    = string
}

variable "block_public_acls" {
  type    = bool
  default = true
}
variable "block_public_policy" {
  type    = bool
  default = true
}
variable "ignore_public_acls" {
  type    = bool
  default = true
}
variable "restrict_public_buckets" {
  type    = bool
  default = true
}

variable "notification_topic_arn" {
  type    = string
  default = ""
}
variable "notification_events" {
  type    = list(any)
  default = ["s3:ObjectCreated:*"]
}

variable "topics" {
  description = ""
  type = list(object({
    topic_arn = optional(string)
    events    = optional(list(string), ["s3:ObjectCreated:*"])
  }))
  default = []
}

variable "cors_rules" {
  description = ""
  type = list(object({
    allowed_headers = optional(list(string))
    allowed_methods = optional(list(string))
    allowed_origins = optional(list(string))
    expose_headers  = optional(list(string))
    max_age_seconds = optional(number)
  }))
  default = []
}

variable "lifecycle_rules" {
  description = "List of maps containing configuration of object lifecycle management."
  type        = any
  default     = []
}


variable "bucket_policy" {
  description = "Custom bucket policy JSON"
  type        = string
  default     = null
}

variable "allowed_iam_user_names" {
  description = "List of IAM user names allowed to access the bucket"
  type        = list(string)
  default     = []
}

variable "additional_policy_statements" {
  description = "Additional policy statements for the bucket"
  type        = any
  default     = []
}
