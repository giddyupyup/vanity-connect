variable "aws_region" {
  description = "AWS region where Lambda services are deployed"
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

variable "services_root" {
  description = "Path to the services folder containing */configuration.yml"
  type        = string
  default     = "../../../services"
}

variable "service_names" {
  description = "Service folder names under services_root to deploy (example: [\"connect-contact\", \"public-api\"])"
  type        = list(string)
  nullable    = false

  validation {
    condition = alltrue([
      for name in var.service_names :
      length(trimspace(name)) > 0
    ])
    error_message = "All service_names entries must be non-empty."
  }

  validation {
    condition     = length(var.service_names) > 0
    error_message = "Set service_names with at least one service folder name."
  }
}

variable "connect_instance_id" {
  description = "Amazon Connect instance ID for aws-connect trigger services"
  type        = string
  default     = null
}

variable "connect_instance_arn" {
  description = "Amazon Connect instance ARN for aws-connect trigger services"
  type        = string
  default     = null
}

variable "dynamodb_table_name" {
  description = "Optional DynamoDB table name injected into service env as TABLE_NAME"
  type        = string
  default     = null
}

variable "dynamodb_table_arn" {
  description = "Optional DynamoDB table ARN used to resolve IAM statement resource placeholders"
  type        = string
  default     = null
}

variable "connect_service_key" {
  description = "Service key (folder name under services/) used as Connect contact flow Lambda"
  type        = string
  default     = "connect-contact"
}

variable "contact_flow_name" {
  description = "Contact flow name created for the Connect-trigger service"
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

variable "shared_api_gateway_id" {
  description = "Existing shared API Gateway HTTP API ID for api-gw trigger services"
  type        = string
  default     = null
}

variable "shared_api_gateway_execution_arn" {
  description = "Execution ARN of existing shared API Gateway HTTP API"
  type        = string
  default     = null
}

variable "shared_api_gateway_endpoint" {
  description = "API endpoint URL of existing shared API Gateway HTTP API"
  type        = string
  default     = null
}
