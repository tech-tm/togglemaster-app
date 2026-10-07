output "rds_instance_identifiers" {
  description = "Identificadores das instâncias RDS"

  value = module.rds.rds_instance_identifiers
}

output "redis_cluster_id" {
  description = "Identificador do cluster Redis"

  value = module.elasticache.redis_cluster_id
}