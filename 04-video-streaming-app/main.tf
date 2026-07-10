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
  input_bucket_id   = module.storage.input_bucket_id
  input_bucket_arn  = module.storage.input_bucket_arn
  source_account_id = data.aws_caller_identity.current.account_id
  tags              = local.tags
}

module "security" {
  source = "./modules/security"

  name   = local.name
  vpc_id = data.aws_vpc.default.id
  tags   = local.tags
}

module "compute" {
  source = "./modules/compute"

  name                     = local.name
  ami_id                   = data.aws_ssm_parameter.al2023.value
  instance_type            = var.instance_type
  subnet_id                = sort(data.aws_subnets.default.ids)[0]
  worker_security_group_id = module.security.worker_security_group_id
  web_security_group_id    = module.security.web_security_group_id
  input_bucket_id          = module.storage.input_bucket_id
  input_bucket_arn         = module.storage.input_bucket_arn
  output_bucket_id         = module.storage.output_bucket_id
  output_bucket_arn        = module.storage.output_bucket_arn
  catalog_table_name       = module.storage.catalog_table_name
  catalog_table_arn        = module.storage.catalog_table_arn
  queue_url                = module.queue.queue_url
  queue_arn                = module.queue.queue_arn
  aws_region               = var.aws_region
  tags                     = local.tags
}
