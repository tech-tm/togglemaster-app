cluster_name    = "togglemaster-eks"
cluster_version = "1.36"

node_group_name = "togglemaster-ng"

instance_types = [
  "t3.medium"
]

desired_size = 2
min_size     = 1
max_size     = 4