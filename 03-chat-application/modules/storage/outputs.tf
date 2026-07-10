output "connections_table_name" {
  value = aws_dynamodb_table.connections.name
}

output "connections_table_arn" {
  value = aws_dynamodb_table.connections.arn
}

output "history_table_name" {
  value = aws_dynamodb_table.history.name
}

output "history_table_arn" {
  value = aws_dynamodb_table.history.arn
}
