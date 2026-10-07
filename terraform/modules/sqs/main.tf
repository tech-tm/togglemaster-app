resource "aws_sqs_queue" "evaluation_queue" {
  name                      = var.queue_name
  message_retention_seconds = 86400
}