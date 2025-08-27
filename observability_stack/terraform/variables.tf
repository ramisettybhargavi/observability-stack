variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "observability-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.29"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "node_instance_types" {
  description = "EKS node instance types"
  type        = list(string)
  default     = ["m5.large", "m5.xlarge"]
}

variable "node_desired_capacity" {
  description = "Desired EKS node count"
  type        = number
  default     = 3
}

variable "node_max_capacity" {
  description = "Max EKS node count"
  type        = number
  default     = 3
}

variable "node_min_capacity" {
  description = "Min EKS node count"
  type        = number
  default     = 1
}
