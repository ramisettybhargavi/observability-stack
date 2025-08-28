# Get availability zones
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Create S3 bucket for Terraform state (optional - if using remote state)
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.cluster_name}-terraform-state-${random_string.suffix.result}"
  
  tags = {
    Name        = "${var.cluster_name}-terraform-state"
    Environment = var.environment
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

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
