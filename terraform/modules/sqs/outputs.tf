output "queue_url" {
  description = "URL da fila SQS"

  value = aws_sqs_queue.evaluation_queue.url
}