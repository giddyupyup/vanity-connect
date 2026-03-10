locals {
  trigger_type = var.config.trigger.type
  create_api_gateway = local.trigger_type == "api-gw" && try(var.config.trigger.api_id, null) == null

  lambda_name = var.config.service.name
  handler     = var.config.service.handler
  runtime     = try(var.config.service.runtime, "nodejs20.x")
  timeout     = try(var.config.service.timeout, 10)
  memory_size = try(var.config.service.memory_size, 256)
  role_create = try(var.config.service.role.create, false)
  role_arn    = local.role_create ? aws_iam_role.this[0].arn : try(var.config.service.role_arn, null)
  role_name   = try(var.config.service.role.name, "${local.lambda_name}-role")
  role_policy_name = try(
    var.config.service.role.policy_name,
    "${local.lambda_name}-policy"
  )
  environment = try(var.config.service.environment, {})
  log_retention_days = try(var.config.service.log_retention_days, 14)
  custom_role_statements = [
    for statement in try(var.config.service.role.statements, []) : {
      Effect   = try(statement.effect, "Allow")
      Action   = try(statement.actions, [])
      Resource = try(statement.resources, [])
    }
  ]
  role_policy_statements = concat(
    [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.this.arn}:*"
        ]
      }
    ],
    local.custom_role_statements
  )

  source_dir  = abspath("${var.service_root}/${var.config.service.source_dir}")
  artifact    = "${path.root}/.terraform/${local.lambda_name}.zip"
  api_method  = upper(try(var.config.trigger.method, "GET"))
  api_path    = try(var.config.trigger.path, "/")
  api_id = local.create_api_gateway ? aws_apigatewayv2_api.http[0].id : try(
    var.config.trigger.api_id,
    null
  )
  api_execution_arn = local.create_api_gateway ? aws_apigatewayv2_api.http[0].execution_arn : try(
    var.config.trigger.api_execution_arn,
    null
  )
  api_endpoint = local.create_api_gateway ? aws_apigatewayv2_api.http[0].api_endpoint : try(
    var.config.trigger.api_endpoint,
    null
  )
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${local.lambda_name}"
  retention_in_days = local.log_retention_days
}

resource "aws_iam_role" "this" {
  count = local.role_create ? 1 : 0
  name  = local.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "this" {
  count = local.role_create ? 1 : 0
  name  = local.role_policy_name
  role  = aws_iam_role.this[0].id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.role_policy_statements
  })
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = local.source_dir
  output_path = local.artifact
}

resource "aws_lambda_function" "this" {
  function_name = local.lambda_name
  role          = local.role_arn
  runtime       = local.runtime
  handler       = local.handler

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  memory_size = local.memory_size
  timeout     = local.timeout

  environment {
    variables = local.environment
  }

  depends_on = [aws_cloudwatch_log_group.this]

  lifecycle {
    precondition {
      condition     = local.role_arn != null && length(trimspace(local.role_arn)) > 0
      error_message = "Set service.role_arn or service.role.create=true in configuration.yml."
    }
  }
}

resource "terraform_data" "api_gateway_validation" {
  count = local.trigger_type == "api-gw" ? 1 : 0

  lifecycle {
    precondition {
      condition     = local.api_id != null && length(trimspace(local.api_id)) > 0
      error_message = "For api-gw trigger, set trigger.api_id or allow module-managed API creation."
    }
    precondition {
      condition     = local.api_execution_arn != null && length(trimspace(local.api_execution_arn)) > 0
      error_message = "For api-gw trigger, set trigger.api_execution_arn or allow module-managed API creation."
    }
  }
}

resource "aws_apigatewayv2_api" "http" {
  count = local.create_api_gateway ? 1 : 0

  name          = "${local.lambda_name}-http-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  count = local.trigger_type == "api-gw" ? 1 : 0

  api_id             = local.api_id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.this.invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "lambda" {
  count = local.trigger_type == "api-gw" ? 1 : 0

  api_id    = local.api_id
  route_key = "${local.api_method} ${local.api_path}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda[0].id}"
}

resource "aws_apigatewayv2_stage" "default" {
  count = local.create_api_gateway ? 1 : 0

  api_id      = local.api_id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  count = local.trigger_type == "api-gw" ? 1 : 0

  statement_id  = "AllowApiGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${local.api_execution_arn}/*/*"
}

resource "aws_lambda_permission" "connect_invoke" {
  count = local.trigger_type == "aws-connect" ? 1 : 0

  statement_id  = "AllowConnectInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "connect.amazonaws.com"
  source_arn    = var.config.trigger.instance_arn
}

resource "aws_connect_lambda_function_association" "this" {
  count = local.trigger_type == "aws-connect" ? 1 : 0

  instance_id  = var.config.trigger.instance_id
  function_arn = aws_lambda_function.this.arn
}
