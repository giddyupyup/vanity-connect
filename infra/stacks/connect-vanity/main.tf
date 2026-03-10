locals {
  rendered_contact_flow = (
    var.connect_lambda_arn == null ? null : (
      var.contact_flow_content != null ? var.contact_flow_content : templatefile("${path.module}/templates/contact-flow.json.tftpl", {
        lambda_arn = var.connect_lambda_arn
      })
    )
  )
}

resource "aws_dynamodb_table" "vanity_calls" {
  name         = "${var.project_name}-calls"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }
}

resource "aws_apigatewayv2_api" "shared_http" {
  name          = "${var.project_name}-shared-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "shared_default" {
  api_id      = aws_apigatewayv2_api.shared_http.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_connect_contact_flow" "vanity_flow" {
  count = var.connect_lambda_arn == null || var.connect_instance_id == null ? 0 : 1

  instance_id = var.connect_instance_id
  name        = var.contact_flow_name
  type        = var.contact_flow_type
  description = "Reads caller number, invokes vanity Lambda, and plays results"
  content     = local.rendered_contact_flow
}
