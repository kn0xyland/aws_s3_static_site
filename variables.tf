variable "name_prefix" {
  description = "Name prefix for resources on AWS"
  default     = ""
}

variable "awsregion" {
  description = "AWS region"
  type        = string
}

variable "zoneid" {
  description = "Existing Route53 Zone ID"
  type        = string
  default     = ""
}

variable "static_bucket_name" {
  description = "Bucket name MUST be the fqdn eg mysite.mydomain.io"
  type        = string
  default     = ""
}

variable "logging_bucket_name" {
  description = "Bucket name MUST be the fqdn eg mysite.mydomain.io"
  type        = string
  default     = ""
}

variable "expire_days" {
  description = "Number of days when logs expire to save on storage costs"
  type        = string
  default     = "7"
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
  default     = ""
}

variable "default_tags" {
  type = map(string)
}

variable "timezone" {
  description = "Timezone "
  type        = string
  default     = ""
}

variable "fqdn" {
  description = "The FQDN for the instance eg natrouter.mydomain.io"
  type        = string
  default     = ""
}