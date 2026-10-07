variable "aws_region" {
  description = "Região AWS"
  type        = string
}

variable "db_username" {
  description = "Usuário administrador do PostgreSQL"
  type        = string
  sensitive   = true
}

variable "databases" {
  description = "Mapeamento dos bancos de dados"
  type = map(object({
    identifier = string
    db_name    = string
  }))
}