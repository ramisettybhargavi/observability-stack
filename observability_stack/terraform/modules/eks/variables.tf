variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "intra_subnets" {
  description = "List of intra subnet IDs"
  type        = list(string)
}

variable "node_security_group_id" {
  description = "Security group ID for EKS node group"
  type        = string
}

variable "node_instance_types" {
  description = "Instance types for EKS node groups"
  type        = list(string)
}

variable "node_desired_capacity" {
  description = "Desired capacity for EKS node group"
  type        = number
}

variable "node_max_capacity" {
  description = "Maximum capacity for EKS node group"
  type        = number
}

variable "node_min_capacity" {
  description = "Minimum capacity for EKS node group"
  type        = number
}
