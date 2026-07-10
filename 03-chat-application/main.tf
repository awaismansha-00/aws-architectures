locals {
  name = "${var.project_name}-${var.environment}"
  tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

module "storage" {
  source = "./modules/storage"

  name = local.name
  tags = local.tags
}

module "queue" {
  source = "./modules/queue"

  name = local.name
  tags = local.tags
}

module "lambda" {
  source = "./modules/lambda"

  name                  = local.name
  connections_table     = module.storage.connections_table_name
  connections_table_arn = module.storage.connections_table_arn
  history_table         = module.storage.history_table_name
  history_table_arn     = module.storage.history_table_arn
  queue_url             = module.queue.queue_url
  queue_arn             = module.queue.queue_arn
  connection_token      = var.connection_token
  tags                  = local.tags
}

module "websocket_api" {
  source = "./modules/websocket_api"

  name                           = local.name
  handler_function_name          = module.lambda.handler_function_name
  handler_function_invoke_arn    = module.lambda.handler_function_invoke_arn
  handler_role_id                = module.lambda.handler_role_id
  authorizer_function_name       = module.lambda.authorizer_function_name
  authorizer_function_invoke_arn = module.lambda.authorizer_function_invoke_arn
  tags                           = local.tags
}
