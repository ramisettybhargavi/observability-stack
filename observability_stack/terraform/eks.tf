# terraform/eks.tf
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  enable_irsa = true                               # Enable IRSA

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

      vpc_security_group_ids = [
        aws_security_group.node_group_one.id
      ]
    }
  }

  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral = {
      description                = "Allow node → control-plane traffic"
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
