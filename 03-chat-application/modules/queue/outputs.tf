output "queue_url" {
  value = aws_sqs_queue.log.url
}

output "queue_arn" {
  value = aws_sqs_queue.log.arn
}
