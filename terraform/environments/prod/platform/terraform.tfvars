ecr_repositories = [
  "auth-service",
  "flag-service", 
  "targeting-service",
  "evaluation-service",
  "analytics-service"
]

sqs_queue_name       = "togglemaster-evaluation"
dynamodb_table_name  = "togglemaster-analytics"