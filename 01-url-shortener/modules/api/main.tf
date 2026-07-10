resource "aws_api_gateway_rest_api" "this" {
  name = var.name

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

resource "aws_api_gateway_resource" "create" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "create"
}

resource "aws_api_gateway_resource" "id" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "{id}"
}

resource "aws_api_gateway_method" "create" {
  rest_api_id      = aws_api_gateway_rest_api.this.id
  resource_id      = aws_api_gateway_resource.create.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_method" "redirect" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.id.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "create" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.create.id
  http_method             = aws_api_gateway_method.create.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.create_function_invoke_arn
}

resource "aws_api_gateway_integration" "redirect" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.id.id
  http_method             = aws_api_gateway_method.redirect.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.redirect_function_invoke_arn
}

resource "aws_lambda_permission" "create" {
  statement_id  = "ApiGatewayCreate"
  action        = "lambda:InvokeFunction"
  function_name = var.create_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/POST/create"
}

resource "aws_lambda_permission" "redirect" {
  statement_id  = "ApiGatewayRedirect"
  action        = "lambda:InvokeFunction"
  function_name = var.redirect_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/GET/*"
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode([aws_api_gateway_integration.create.id, aws_api_gateway_integration.redirect.id]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = "prod"
  tags          = var.tags
}

resource "aws_api_gateway_api_key" "client" {
  name    = "${var.name}-client"
  enabled = true
  tags    = var.tags
}

resource "aws_api_gateway_usage_plan" "safe" {
  name = "${var.name}-safe"

  api_stages {
    api_id = aws_api_gateway_rest_api.this.id
    stage  = aws_api_gateway_stage.prod.stage_name
  }

  throttle_settings {
    burst_limit = var.burst_limit
    rate_limit  = var.rate_limit
  }

  quota_settings {
    limit  = 5000
    period = "DAY"
  }

  tags = var.tags
}

resource "aws_api_gateway_usage_plan_key" "client" {
  key_id        = aws_api_gateway_api_key.client.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.safe.id
}
