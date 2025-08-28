provider "aws" {
  region = var.region
}

module "vpc" {
  source = "./modules/vpc"
}

module "ecr" {
  source    = "./modules/ecr"
  repo_name = var.repo_name
}

module "ecs" {
  source          = "./modules/ecs"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  public_subnets  = module.vpc.public_subnets
  repo_url        = module.ecr.repo_url
  region          = var.region
  app_name        = "myapp"
}
