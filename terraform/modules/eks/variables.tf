variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
  default     = "togglemaster-eks"
}

variable "cluster_version" {
  description = "Versao do Kubernetes"
  type        = string
  default     = "1.36"
}

variable "node_group_name" {
  description = "Nome do Node Group"
  type        = string
  default     = "togglemaster-ng"
}

variable "instance_types" {
  description = "Tipos de instancia para os worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "desired_size" {
  description = "Quantidade desejada de instancias nos nos"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Quantidade minima de instancias"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Quantidade maxima de instancias"
  type        = number
  default     = 4
}