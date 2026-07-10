resource "aws_api_gateway_rest_api" "this" {
  name = var.name

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

locals {
  methods = {
    "upload-url"   = "GET"
    "download-url" = "GET"
    "files"        = "GET"
    "delete-file"  = "DELETE"
  }
}

resource "aws_api_gateway_resource" "route" {
  for_each = local.methods

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = each.key
}

resource "aws_api_gateway_method" "route" {
  for_each = local.methods

  rest_api_id      = aws_api_gateway_rest_api.this.id
  resource_id      = aws_api_gateway_resource.route[each.key].id
  http_method      = each.value
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "route" {
  for_each = local.methods

  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.route[each.key].id
  http_method             = aws_api_gateway_method.route[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.api_function_invoke_arn
}

resource "aws_lambda_permission" "api" {
  statement_id  = "ApiGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.api_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*"
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    routes = sha1(jsonencode([for v in aws_api_gateway_integration.route : v.id]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = "prod"
  tags          = var.tags
}

resource "aws_api_gateway_api_key" "client" {
  name    = "${var.name}-ui"
  enabled = true
  tags    = var.tags
}

resource "aws_api_gateway_usage_plan" "this" {
  name = "${var.name}-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.this.id
    stage  = aws_api_gateway_stage.prod.stage_name
  }

  throttle_settings {
    rate_limit  = 5
    burst_limit = 10
  }

  quota_settings {
    limit  = 1000
    period = "MONTH"
  }

  tags = var.tags
}

resource "aws_api_gateway_usage_plan_key" "client" {
  key_id        = aws_api_gateway_api_key.client.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.this.id
}
