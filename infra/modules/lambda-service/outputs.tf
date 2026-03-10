output "lambda_function_arn" {
  value = aws_lambda_function.this.arn
}

output "api_endpoint" {
  value = local.trigger_type == "api-gw" ? local.api_endpoint : null
}
