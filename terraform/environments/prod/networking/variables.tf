variable "aws_region" {
  description = "Região AWS"
  type        = string
}

variable "eks_node_security_group" {
  description = "Security Group do EKS"
  type        = string
  default     = ""
}

variable "terraform_state_bucket" {
  description = "Bucket S3 utilizado para armazenar os Terraform States"
  type        = string
}