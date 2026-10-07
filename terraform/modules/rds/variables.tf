variable "databases" {
  description = "Mapeamento dos bancos de dados a serem criados"

  type = map(object({
    identifier = string
    db_name    = string
  }))
}

variable "instance_class" {
  description = "Classe da instância RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Tamanho do storage em GB"
  type        = number
  default     = 20
}

variable "backup_retention_period" {
  description = "Período de retenção de backup em dias"
  type        = number
  default     = 0
}