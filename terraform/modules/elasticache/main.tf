data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
data "aws_ssm_parameter" "redis_password" {
  name = "/togglemaster/prod/redis/credentials"
}

locals {
  redis_creds = jsondecode(data.aws_ssm_parameter.redis_password.value)
}

resource "aws_security_group" "redis" {
  name        = "togglemaster-redis-sg"
  description = "Security Group do Redis"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = var.redis_port
    to_port     = var.redis_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project     = "ToggleMaster"
    Environment = "AWSAcademy"
    Service     = "redis"
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "togglemaster-redis-subnet-group"
  subnet_ids = data.aws_subnets.all.ids
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = var.cluster_id
  engine               = "redis"
  node_type            = var.node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = var.redis_port

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]

  tags = {
    Project     = "ToggleMaster"
    Environment = "AWSAcademy"
    Service     = "redis"
  }
}