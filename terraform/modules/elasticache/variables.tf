variable "cluster_id" {
  description = "Redis cluster ID"
  type        = string
  default     = "togglemaster-redis"
}

variable "node_type" {
  description = "Redis node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_port" {
  description = "Redis port"
  type        = number
  default     = 6379
}