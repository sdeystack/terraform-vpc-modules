# SKELETON ONLY — DO NOT APPLY. Same modules as dev, different variables.

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "terraform-vpc-modules"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name_prefix = var.name_prefix
  cidr_block  = var.vpc_cidr
  azs         = var.azs
}

module "compute" {
  source = "../../modules/compute"

  name_prefix        = var.name_prefix
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  instance_type      = var.instance_type
  allowed_http_cidrs = var.allowed_http_cidrs
}
