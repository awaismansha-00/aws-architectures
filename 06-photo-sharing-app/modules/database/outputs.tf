output "secret_name" {
  value = aws_secretsmanager_secret.db.name
}

output "secret_arn" {
  value = aws_secretsmanager_secret.db.arn
}
