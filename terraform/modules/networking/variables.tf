variable "eks_node_security_group" {
  description = "Security Group dos Worker Nodes do EKS"
  type        = string
}

variable "rds_instance_identifiers" {
  description = "Identificadores das instâncias RDS"
  type        = set(string)
}

variable "redis_cluster_id" {
  description = "Identificador do cluster Redis"
  type        = string
}