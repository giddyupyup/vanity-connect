variable "aws_region" {
  description = "AWS region where infrastructure will be deployed"
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

variable "connect_instance_id" {
  description = "Amazon Connect instance ID"
  type        = string
  default     = null
}

variable "connect_instance_arn" {
  description = "Amazon Connect instance ARN"
  type        = string
  default     = null
}

variable "connect_lambda_arn" {
  description = "Lambda ARN to embed in contact flow content"
  type        = string
  default     = null
}

variable "contact_flow_name" {
  description = "Contact flow name"
  type        = string
  default     = "Vanity Number Flow"
}

variable "contact_flow_type" {
  description = "Amazon Connect contact flow type"
  type        = string
  default     = "CONTACT_FLOW"
}

variable "contact_flow_content" {
  description = "Optional raw JSON content for contact flow. If null, template file is used."
  type        = string
  default     = null
}
