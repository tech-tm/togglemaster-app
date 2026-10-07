terraform {
  backend "s3" {
    key     = "prod/security/terraform.tfstate"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "security" {
  source = "../../../modules/security"

  db_username = var.db_username
  databases   = var.databases
}