data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "all" {
  for_each = toset(data.aws_subnets.all.ids)

  id = each.key
}

locals {
  valid_subnets = [
    for s in data.aws_subnet.all :
    s.id
    if !endswith(s.availability_zone, "e")
  ]
}

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = data.aws_iam_role.lab_role.arn

  vpc_config {
    subnet_ids              = local.valid_subnets
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = {
    Project     = "ToggleMaster"
    Environment = "AWSAcademy"
  }
}

resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = var.node_group_name
  node_role_arn   = data.aws_iam_role.lab_role.arn
  subnet_ids      = local.valid_subnets

  capacity_type  = "ON_DEMAND"
  ami_type       = "AL2023_x86_64_STANDARD"
  disk_size      = 20
  instance_types = var.instance_types

  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    environment = "academy"
    project     = "togglemaster"
  }

  tags = {
    Project     = "ToggleMaster"
    Environment = "AWSAcademy"
  }

  depends_on = [
    aws_eks_cluster.eks
  ]
}

resource "kubernetes_namespace" "togglemaster" {
  metadata {
    name = "togglemaster"
  }

  depends_on = [
    aws_eks_cluster.eks,
    aws_eks_node_group.nodes
  ]
}