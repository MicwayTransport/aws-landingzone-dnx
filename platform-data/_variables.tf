variable "aws_region" {
  type = string
}

variable "global_tags" {
  description = "Global tags applied to every AWS resource via provider default_tags. Sourced from _workspaces/globals.hcl."
  type        = map(string)
  default     = {}
}

variable "aws_account_id" {
  type = string
}

variable "account_name" {
  type = string
}

variable "org_name" {
  type = string
}

variable "has_vpc" {
  type    = bool
  default = true
}

variable "mq" {
  type = any
  default = {
    brokers = []
  }
}

variable "buckets" {
  type    = list(any)
  default = []
}

variable "elasticache" {
  type = any
  default = {
    redis       = []
    redis_users = []
  }
}

variable "rds" {
  type = any
  default = {
    dbs = []
  }
}

variable "dms" {
  type = any
  default = {
    endpoint = []
  }
}

variable "ecs_cluster_sgs" {
  type    = any
  default = {}
}

variable "notifications_sns_topic_arn" {
  type    = string
  default = ""
}

variable "iam_users" {
  type    = any
  default = []
}

variable "ec2" {
  type    = any
  default = []
}
