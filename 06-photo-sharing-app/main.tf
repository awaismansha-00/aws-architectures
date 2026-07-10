locals {
  name = "${var.project_name}-${var.environment}"
  tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

module "network" {
  source = "./modules/network"

  name               = local.name
  availability_zones = data.aws_availability_zones.available.names
  tags               = local.tags
}

module "storage" {
  source = "./modules/storage"

  name = local.name
  tags = local.tags
}

module "security" {
  source = "./modules/security"

  name   = local.name
  vpc_id = module.network.vpc_id
  tags   = local.tags
}

module "web" {
  source = "./modules/web"

  name                  = local.name
  ami_id                = data.aws_ssm_parameter.al2023.value
  instance_type         = var.instance_type
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  web_security_group_id = module.security.web_security_group_id
  photo_bucket_id       = module.storage.bucket_id
  photo_bucket_arn      = module.storage.bucket_arn
  db_secret_name        = module.database.secret_name
  db_secret_arn         = module.database.secret_arn
  container_image       = var.container_image
  tags                  = local.tags
}

module "database" {
  source = "./modules/database"

  name                 = local.name
  db_name              = var.db_name
  db_instance_class    = var.db_instance_class
  private_subnet_ids   = module.network.private_subnet_ids
  db_security_group_id = module.security.db_security_group_id
  tags                 = local.tags
}

module "metadata_lambda" {
  source = "./modules/metadata_lambda"

  name              = local.name
  bucket_id         = module.storage.bucket_id
  bucket_arn        = module.storage.bucket_arn
  alb_dns_name      = module.web.alb_dns_name
  source_account_id = data.aws_caller_identity.current.account_id
  tags              = local.tags
}
