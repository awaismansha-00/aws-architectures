resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "input" {
  bucket        = "${var.name}-input-${random_id.suffix.hex}"
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket" "output" {
  bucket        = "${var.name}-output-${random_id.suffix.hex}"
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "buckets" {
  for_each = {
    input  = aws_s3_bucket.input.id
    output = aws_s3_bucket.output.id
  }

  bucket                  = each.value
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "buckets" {
  for_each = {
    input  = aws_s3_bucket.input.id
    output = aws_s3_bucket.output.id
  }

  bucket = each.value

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "catalog" {
  name         = "${var.name}-catalog"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "video_id"

  attribute {
    name = "video_id"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = var.tags
}
