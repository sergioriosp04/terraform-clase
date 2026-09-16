module "network" {
  source       = "./modules/network"
  vpc_cidr     = var.vpc_cidr
  pub_subnets  = var.pub_subnets
  priv_subnets = var.priv_subnets
}