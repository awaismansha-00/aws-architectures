output "input_bucket_id" {
  value = aws_s3_bucket.input.id
}

output "input_bucket_arn" {
  value = aws_s3_bucket.input.arn
}

output "output_bucket_id" {
  value = aws_s3_bucket.output.id
}

output "output_bucket_arn" {
  value = aws_s3_bucket.output.arn
}

output "catalog_table_name" {
  value = aws_dynamodb_table.catalog.name
}

output "catalog_table_arn" {
  value = aws_dynamodb_table.catalog.arn
}
