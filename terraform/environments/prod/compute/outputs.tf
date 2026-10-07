output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Certificate Authority do cluster EKS"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_primary_security_group_id" {
  description = "Security Group principal do cluster EKS"
  value       = module.eks.cluster_primary_security_group_id
}

output "node_group_id" {
  description = "ID do Node Group"
  value       = module.eks.node_group_id
}

output "node_security_group_id" {
  description = "Security Group utilizado pelos nodes do EKS"
  value       = module.eks.node_security_group_id
}