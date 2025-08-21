module "api_gateway" {
  source      = "./modules/api_gateway"
  api_name    = var.api_name
  aws_region  = var.aws_region
  environment = var.environment
  methods     = var.methods
}
