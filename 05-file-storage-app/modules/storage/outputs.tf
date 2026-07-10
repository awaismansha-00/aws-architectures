output "bucket_id" {
  value = aws_s3_bucket.storage.id
}

output "bucket_arn" {
  value = aws_s3_bucket.storage.arn
}

output "metadata_table_name" {
  value = aws_dynamodb_table.metadata.name
}

output "metadata_table_arn" {
  value = aws_dynamodb_table.metadata.arn
}
