cluster_name    = "togglemaster-eks"
cluster_version = "1.36"

node_group_name = "togglemaster-ng"

instance_types = [
  "t3.medium"
]

# t3.medium permite ~17 pods/no (limite do VPC CNI padrao).
# Com 3 nos temos ~51 pods disponiveis, folga confortavel para:
#   - kube-system (~6)
#   - argocd      (~7)
#   - ingress-nginx (1)
#   - togglemaster (5)
#   - observability (~10)
# Antes com 2 nos (~34 pods) estava no limite e Jobs do kube-prometheus-stack
# falhavam com "failed to assign an IP address".
desired_size = 3
min_size     = 1
max_size     = 4