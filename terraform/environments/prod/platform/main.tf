terraform {
  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "ecr" {
  source = "../../../modules/ecr"

  ecr_repositories = var.ecr_repositories
}

module "sqs" {
  source = "../../../modules/sqs"

  queue_name = var.sqs_queue_name
}

module "dynamodb" {
  source = "../../../modules/dynamodb"

  table_name = var.dynamodb_table_name
}