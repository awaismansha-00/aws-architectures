output "bucket" {
  value = aws_s3_bucket.state.id
}

output "dynamodb_table" {
  value = aws_dynamodb_table.locks.name
}

output "region" {
  value = "us-east-1"
}

output "key" {
  value = "06-photo-sharing-app/terraform.tfstate"
}

output "backend_config" {
  value = <<-EOT
    bucket         = "${aws_s3_bucket.state.id}"
    key            = "06-photo-sharing-app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "${aws_dynamodb_table.locks.name}"
    encrypt        = true
    use_lockfile   = true
  EOT
}
