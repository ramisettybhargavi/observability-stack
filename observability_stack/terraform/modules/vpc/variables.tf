variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "azs" {
  type        = list(string)
  description = "List of availability zones"
}
