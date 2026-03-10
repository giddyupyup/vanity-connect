output "dynamodb_table_name" {
  value = aws_dynamodb_table.vanity_calls.name
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.vanity_calls.arn
}

output "shared_api_gateway_id" {
  value = aws_apigatewayv2_api.shared_http.id
}

output "shared_api_gateway_execution_arn" {
  value = aws_apigatewayv2_api.shared_http.execution_arn
}

output "shared_api_gateway_endpoint" {
  value = aws_apigatewayv2_api.shared_http.api_endpoint
}

output "contact_flow_id" {
  value = try(aws_connect_contact_flow.vanity_flow[0].contact_flow_id, null)
}
