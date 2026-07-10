resource "aws_apigatewayv2_api" "chat" {
  name                       = var.name
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
  tags                       = var.tags
}

data "aws_iam_policy_document" "manage_connections" {
  statement {
    actions   = ["execute-api:ManageConnections"]
    resources = ["${aws_apigatewayv2_api.chat.execution_arn}/*"]
  }
}

resource "aws_iam_role_policy" "manage_connections" {
  role   = var.handler_role_id
  policy = data.aws_iam_policy_document.manage_connections.json
}

resource "aws_apigatewayv2_integration" "handler" {
  api_id             = aws_apigatewayv2_api.chat.id
  integration_type   = "AWS_PROXY"
  integration_uri    = var.handler_function_invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_authorizer" "connect" {
  api_id           = aws_apigatewayv2_api.chat.id
  name             = "connection-token"
  authorizer_type  = "REQUEST"
  authorizer_uri   = var.authorizer_function_invoke_arn
  identity_sources = ["route.request.querystring.token"]
}

resource "aws_apigatewayv2_route" "connect" {
  api_id             = aws_apigatewayv2_api.chat.id
  route_key          = "$connect"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.connect.id
  target             = "integrations/${aws_apigatewayv2_integration.handler.id}"
}

resource "aws_apigatewayv2_route" "routes" {
  for_each = toset(["$disconnect", "$default", "setName", "sendMessage"])

  api_id    = aws_apigatewayv2_api.chat.id
  route_key = each.key
  target    = "integrations/${aws_apigatewayv2_integration.handler.id}"
}

resource "aws_lambda_permission" "handler" {
  statement_id  = "WebSocketInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.handler_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.chat.execution_arn}/*"
}

resource "aws_lambda_permission" "authorizer" {
  statement_id  = "WebSocketAuthorize"
  action        = "lambda:InvokeFunction"
  function_name = var.authorizer_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.chat.execution_arn}/*/$connect"
}

resource "aws_apigatewayv2_stage" "production" {
  api_id      = aws_apigatewayv2_api.chat.id
  name        = "production"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 100
    throttling_rate_limit  = 50
  }

  tags = var.tags
}
