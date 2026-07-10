output "worker_security_group_id" {
  value = aws_security_group.worker.id
}

output "web_security_group_id" {
  value = aws_security_group.web.id
}
