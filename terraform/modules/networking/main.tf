data "aws_db_instance" "databases" {
  for_each               = var.rds_instance_identifiers
  db_instance_identifier = each.key
}

data "aws_elasticache_cluster" "redis" {
  cluster_id = var.redis_cluster_id
}


# ============================================================
# POSTGRES
# ============================================================

resource "aws_vpc_security_group_ingress_rule" "postgres" {
  for_each = var.eks_node_security_group != "" ? data.aws_db_instance.databases : {}

  security_group_id            = each.value.vpc_security_groups[0]
  referenced_security_group_id = var.eks_node_security_group
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}


# ============================================================
# REDIS
# ============================================================

resource "aws_vpc_security_group_ingress_rule" "redis" {
  count = var.eks_node_security_group != "" ? 1 : 0

  security_group_id            = tolist(data.aws_elasticache_cluster.redis.security_group_ids)[0]
  referenced_security_group_id = var.eks_node_security_group
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
}