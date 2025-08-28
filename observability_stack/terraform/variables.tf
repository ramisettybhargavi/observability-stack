variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "observability-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "node_instance_types" {
  description = "Instance types for EKS node groups"
  type        = list(string)
  default     = ["m5.large", "m5.xlarge"]
}

variable "node_desired_capacity" {
  description = "Desired capacity for EKS node group"
  type        = number
  default     = 3
}

variable "node_max_capacity" {
  description = "Maximum capacity for EKS node group"
  type        = number
  default     = 10
}

variable "node_min_capacity" {
  description = "Minimum capacity for EKS node group"
  type        = number
  default     = 1
}
