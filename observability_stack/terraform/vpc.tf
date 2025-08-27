# terraform/vpc.tf

# Fetch the first three available AZs for high availability
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name                 = "${var.cluster_name}-vpc"
  cidr                 = var.vpc_cidr
  azs                  = slice(data.aws_availability_zones.available.names, 0, 3)

# Calculate subnets per AZ
  private_subnets = [
    for idx, az in slice(data.aws_availability_zones.available.names, 0, 3) :
      cidrsubnet(var.vpc_cidr, 4, idx)
  ]
  public_subnets = [
    for idx, az in slice(data.aws_availability_zones.available.names, 0, 3):
    cidrsubnet(var.vpc_cidr, 8, idx + 48)
  ]
  intra_subnets = [
    for idx, az in slice(data.aws_availability_zones.available.names, 0, 3):
    cidrsubnet(var.vpc_cidr, 8, idx + 52)
  ]

  # NAT gateways for internet egress from private subnets
  enable_nat_gateway   = true
  single_nat_gateway   = false

  # DNS settings for Kubernetes
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Subnet tags for Kubernetes service load balancers
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  # Global tags
  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    Environment                                = var.environment
    Terraform                                  = "true"
  }
}
