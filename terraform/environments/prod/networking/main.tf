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

# ============================================================
# REMOTE STATE - DATA
# ============================================================
data "terraform_remote_state" "data" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "prod/data/terraform.tfstate"
    region = var.aws_region
  }
}

# ============================================================
# REMOTE STATE - COMPUTE
# ============================================================
data "terraform_remote_state" "compute" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "prod/compute/terraform.tfstate"
    region = var.aws_region
  }
}

# ============================================================
# LOCAL: EKS SECURITY GROUP (apply usa remote state, destroy usa var vazia)
# ============================================================
locals {
  eks_sg = var.eks_node_security_group != "" ? var.eks_node_security_group : try(data.terraform_remote_state.compute.outputs.cluster_primary_security_group_id, "")
}

# ============================================================
# NETWORKING MODULE
# ============================================================
module "networking" {
  source = "../../../modules/networking"

  rds_instance_identifiers = toset(values(data.terraform_remote_state.data.outputs.rds_instance_identifiers))
  eks_node_security_group  = local.eks_sg
  redis_cluster_id         = data.terraform_remote_state.data.outputs.redis_cluster_id
}