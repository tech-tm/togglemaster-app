output "cluster_name" {
  value = aws_eks_cluster.eks.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "cluster_certificate_authority_data" {
  value     = aws_eks_cluster.eks.certificate_authority[0].data
  sensitive = true
}

output "cluster_primary_security_group_id" {
  value = aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id
}

output "node_group_id" {
  value = aws_eks_node_group.nodes.id
}

output "node_security_group_id" {
  value = aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id
}
