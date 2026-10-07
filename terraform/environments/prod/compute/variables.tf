variable "aws_region" {
  description = "Região AWS"
  type        = string
}

variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
}

variable "cluster_version" {
  description = "Versão do Kubernetes"
  type        = string
}

variable "node_group_name" {
  description = "Nome do Node Group"
  type        = string
}

variable "instance_types" {
  description = "Tipos de instância dos Worker Nodes"
  type        = list(string)
}

variable "desired_size" {
  description = "Quantidade desejada de nodes"
  type        = number
}

variable "min_size" {
  description = "Quantidade mínima de nodes"
  type        = number
}

variable "max_size" {
  description = "Quantidade máxima de nodes"
  type        = number
}