variable "aws_region" {
  description = "AWS region where web hosting infrastructure is deployed"
  type        = string
}

variable "aws_access_key_id" {
  description = "Optional AWS access key ID for provider authentication"
  type        = string
  default     = null
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "Optional AWS secret access key for provider authentication"
  type        = string
  default     = null
  sensitive   = true
}

variable "project_name" {
  description = "Project prefix for named AWS resources"
  type        = string
  default     = "connect-vanity"
}

variable "callers_api_url" {
  description = "Fully qualified callers API endpoint (for runtime-config.json)"
  type        = string
}
