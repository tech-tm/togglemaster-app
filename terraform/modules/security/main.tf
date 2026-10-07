resource "random_password" "db_password" {
  for_each = var.databases

  length  = 16
  special = false
}

resource "aws_ssm_parameter" "db_secrets" {
  for_each = var.databases

  name = "/togglemaster/prod/${each.key}/credentials"

  type = "SecureString"

  value = jsonencode({
    username = var.db_username
    password = random_password.db_password[each.key].result
  })

  tags = {
    Project     = "ToggleMaster"
    Environment = "AWSAcademy"
    Service     = each.key
  }
}

resource "random_password" "redis_password" {
  length  = 16
  special = false
}

resource "aws_ssm_parameter" "redis_secret" {
  name = "/togglemaster/prod/redis/credentials"

  type = "SecureString"

  value = jsonencode({
    password = random_password.redis_password.result
  })

  tags = {
    Project     = "ToggleMaster"
    Environment = "AWSAcademy"
    Service     = "redis"
  }
}

# Gerar chaves aleatórias para evaluation-service
resource "random_password" "master_key" {
  length  = 32
  special = false
}

resource "random_password" "service_api_key" {
  length  = 32
  special = false
}

# Armazenar no SSM
resource "aws_ssm_parameter" "master_key" {
  name        = "/togglemaster/prod/evaluation/master_key"
  description = "MASTER_KEY para evaluation-service"
  type        = "SecureString"
  value       = random_password.master_key.result
  tags = {
    Project     = "ToggleMaster"
    Environment = "AWSAcademy"
    Service     = "evaluation"
  }
}

resource "aws_ssm_parameter" "service_api_key" {
  name        = "/togglemaster/prod/evaluation/service_api_key"
  description = "SERVICE_API_KEY para evaluation-service"
  type        = "SecureString"
  value       = random_password.service_api_key.result
  tags = {
    Project     = "ToggleMaster"
    Environment = "AWSAcademy"
    Service     = "evaluation"
  }
}