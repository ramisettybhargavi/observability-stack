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
  private_subnets      = [for i in range(3) : cidrsubnet(var.vpc_cidr, 4, i)]
  public_subnets       = [for i in range(3) : cidrsubnet(var.vpc_cidr, 8, i + 48)]
  intra_subnets        = [for i in range(3) : cidrsubnet(var.vpc_cidr, 8, i + 52)]
  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = { "kubernetes.io/role/elb" = "1" }
  private_subnet_tags = { "kubernetes.io/role/internal-elb" = "1" }

  tags = {
    Name        = "${var.cluster_name}-vpc"
    Environment = var.environment
    Terraform   = "true"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns            = { most_recent = true }
    kube-proxy         = { most_recent = true }
    vpc-cni            = { most_recent = true }
    aws-ebs-csi-driver = { most_recent = true }
  }

  eks_managed_node_group_defaults = {
    instance_types = var.node_instance_types
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }

  eks_managed_node_groups = {
    observability_nodes = {
      name            = "observability-nodes"
      instance_types  = var.node_instance_types
      min_size        = var.node_min_capacity
      max_size        = var.node_max_capacity
      desired_size    = var.node_desired_capacity
      pre_bootstrap_user_data = <<-EOT
        #!/bin/bash
        /etc/eks/bootstrap.sh ${var.cluster_name}
      EOT
      vpc_security_group_ids = [aws_security_group.node_group_one.id]
    }
  }

  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral = {
      description                = "Node groups to control plane"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      source_node_security_group = true
      type                       = "ingress"
    }
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}
