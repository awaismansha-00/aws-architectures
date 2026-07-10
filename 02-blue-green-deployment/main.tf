locals {
  name = "${var.project_name}-${var.environment}"
  tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

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

module "security" {
  source = "./modules/security"

  name   = local.name
  vpc_id = module.network.vpc_id
  tags   = local.tags
}

module "compute" {
  source = "./modules/compute"

  name              = local.name
  ami_id            = data.aws_ssm_parameter.al2023.value
  instance_type     = var.instance_type
  subnet_ids        = module.network.public_subnet_ids
  security_group_id = module.security.web_security_group_id
  tags              = local.tags
}

module "load_balancer" {
  source = "./modules/load_balancer"

  name                  = local.name
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
  instance_ids          = module.compute.instance_ids
  green_traffic_weight  = var.green_traffic_weight
  tags                  = local.tags
}
