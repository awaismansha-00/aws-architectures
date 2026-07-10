locals {
  name = "${var.project_name}-${var.environment}"
  tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

module "storage" {
  source = "./modules/storage"

  name = local.name
  tags = local.tags
}

module "queue" {
  source = "./modules/queue"

  name              = local.name
  bucket_id         = module.storage.bucket_id
  bucket_arn        = module.storage.bucket_arn
  source_account_id = data.aws_caller_identity.current.account_id
  tags              = local.tags
}

module "lambda" {
  source = "./modules/lambda"

  name               = local.name
  bucket_id          = module.storage.bucket_id
  bucket_arn         = module.storage.bucket_arn
  metadata_table     = module.storage.metadata_table_name
  metadata_table_arn = module.storage.metadata_table_arn
  queue_arn          = module.queue.queue_arn
  tags               = local.tags
}

module "api" {
  source = "./modules/api"

  name                    = local.name
  api_function_name       = module.lambda.api_function_name
  api_function_invoke_arn = module.lambda.api_function_invoke_arn
  tags                    = local.tags
}

module "ui" {
  source = "./modules/ui"

  name          = local.name
  ami_id        = data.aws_ssm_parameter.al2023.value
  instance_type = var.instance_type
  subnet_id     = sort(data.aws_subnets.default.ids)[0]
  vpc_id        = data.aws_vpc.default.id
  api_url       = module.api.invoke_url
  api_key       = module.api.api_key_value
  tags          = local.tags
}
