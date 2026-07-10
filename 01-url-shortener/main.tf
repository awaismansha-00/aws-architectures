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

module "lambda" {
  source = "./modules/lambda"

  name       = local.name
  table_name = module.storage.table_name
  table_arn  = module.storage.table_arn
  tags       = local.tags
}

module "api" {
  source = "./modules/api"

  name                         = local.name
  create_function_name         = module.lambda.create_function_name
  create_function_invoke_arn   = module.lambda.create_function_invoke_arn
  redirect_function_name       = module.lambda.redirect_function_name
  redirect_function_invoke_arn = module.lambda.redirect_function_invoke_arn
  rate_limit                   = var.rate_limit
  burst_limit                  = var.burst_limit
  tags                         = local.tags
}
