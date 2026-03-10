output "lambda_function_arns" {
  value = {
    for key, mod in module.service :
    key => mod.lambda_function_arn
  }
}

output "api_endpoints" {
  value = {
    for key, mod in module.service :
    key => mod.api_endpoint
  }
}

output "connect_lambda_arn" {
  value = try(module.service[var.connect_service_key].lambda_function_arn, null)
}

output "public_api_endpoint" {
  value = try(module.service["public-api"].api_endpoint, null)
}

output "contact_flow_id" {
  value = try(aws_connect_contact_flow.service_flow[0].contact_flow_id, null)
}
