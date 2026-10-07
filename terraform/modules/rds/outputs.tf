output "rds_instance_identifiers" {
  description = "Identificadores das instâncias RDS"

  value = {
    for k, v in aws_db_instance.postgres :
    k => v.identifier
  }
}

output "rds_endpoints" {
  description = "Endpoints das instâncias RDS"

  value = {
    for k, v in aws_db_instance.postgres :
    k => v.endpoint
  }
}

output "rds_databases" {
  description = "Nomes dos bancos de dados"

  value = {
    for k, v in aws_db_instance.postgres :
    k => v.db_name
  }
}