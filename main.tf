module "network" {
  source       = "./modules/network"
  vpc_cidr     = var.vpc_cidr
  pub_subnets  = var.pub_subnets
  priv_subnets = var.priv_subnets
}
module "security" {
  source = "./modules/security"
  vpc_id = module.network.vpc_id
}

module "compute" {
  source    = "./modules/compute"
  subnet_id = module.network.public_subnet_ids[0]
  sg_id     = module.security.sg_id
  key_name  = var.key_name
}

module "load_balancer" {
  source      = "./modules/load_balancer"
  vpc_id      = module.network.vpc_id
  subnet_ids  = module.network.public_subnet_ids
  sg_id       = module.security.alb_sg_id
  instance_id = module.compute.instance_id
}
