

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  cluster_name   = var.cluster_name
  vpc_cidr       = var.vpc_cidr
  environment    = var.environment
  azs            = slice(data.aws_availability_zones.available.names, 0, 3)
}

# Security Groups Module
module "security" {
  source = "./modules/security"
  
  cluster_name = var.cluster_name
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = module.vpc.vpc_cidr_block
}

# EKS Module
module "eks" {
  source = "./modules/eks"
  
  cluster_name               = var.cluster_name
  cluster_version           = var.cluster_version
  environment               = var.environment
  vpc_id                    = module.vpc.vpc_id
  private_subnets           = module.vpc.private_subnets
  intra_subnets             = module.vpc.intra_subnets
  node_security_group_id    = module.security.node_group_security_group_id
  node_instance_types       = var.node_instance_types
  node_desired_capacity     = var.node_desired_capacity
  node_max_capacity         = var.node_max_capacity
  node_min_capacity         = var.node_min_capacity
}

