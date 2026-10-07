variable "aws_region" {
  description = "Região AWS"
  type        = string
}

variable "databases" {
  description = "Mapeamento dos bancos de dados"
  type = map(object({
    identifier = string
    db_name    = string
  }))
}