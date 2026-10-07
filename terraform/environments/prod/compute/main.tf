# ------------------------------------------------------------------
# PROVIDERS
# ------------------------------------------------------------------

terraform {
  backend "s3" {
    key            = "prod/compute/terraform.tfstate"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "eks" {
  source = "../../../modules/eks"

  cluster_name     = var.cluster_name
  cluster_version  = var.cluster_version
  node_group_name  = var.node_group_name
  instance_types   = var.instance_types
  desired_size     = var.desired_size
  min_size         = var.min_size
  max_size         = var.max_size
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}


provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}


resource "aws_ssm_parameter" "cluster_name" {
  name  = "/togglemaster/prod/cluster-name"
  type  = "String"
  value = module.eks.cluster_name

  tags = {
    Project     = "ToggleMaster"
    Environment = "prod"
  }
}