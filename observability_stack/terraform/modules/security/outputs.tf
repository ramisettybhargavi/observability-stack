output "node_group_security_group_id" {
  description = "Security group ID for EKS node group"
  value       = aws_security_group.node_group_one.id
}

output "observability_services_security_group_id" {
  description = "Security group ID for observability services"
  value       = aws_security_group.observability_services.id
}
