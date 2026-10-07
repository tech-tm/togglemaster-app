output "ssm_db_parameter_names" {
  description = "Nomes dos parâmetros SSM das credenciais dos bancos"

  value = {
    for k, v in aws_ssm_parameter.db_secrets :
    k => v.name
  }
}

output "ssm_redis_parameter_name" {
  description = "Nome do parâmetro SSM das credenciais do Redis"

  value = aws_ssm_parameter.redis_secret.name
}