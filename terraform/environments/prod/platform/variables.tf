variable "aws_region" {
  description = "Região AWS"
  type        = string
}

variable "ecr_repositories" {
  description = "Repositórios ECR"
  type        = list(string)
}

variable "sqs_queue_name" {
  description = "Nome da fila SQS"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB"
  type        = string
}