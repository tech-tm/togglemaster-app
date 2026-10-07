output "ecr_repository_urls" {
  description = "URLs dos repositórios ECR"

  value = {
    for k, v in aws_ecr_repository.repositories :
    k => v.repository_url
  }
}