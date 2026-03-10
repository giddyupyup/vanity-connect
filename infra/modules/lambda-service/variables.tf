variable "config" {
  description = "Decoded service configuration from configuration.yml"
  type        = any
}

variable "service_root" {
  description = "Absolute path to the service root folder"
  type        = string
}
