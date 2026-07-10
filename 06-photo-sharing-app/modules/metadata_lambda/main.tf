data "archive_file" "metadata" {
  type        = "zip"
  source_file = "${path.root}/lambda/metadata.py"
  output_path = "${path.root}/lambda/metadata.zip"
}

data "aws_iam_policy_document" "lambda_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "metadata" {
  name               = "${var.name}-metadata"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
  tags               = var.tags
}

resource "aws_cloudwatch_log_group" "metadata" {
  name              = "/aws/lambda/${var.name}-metadata"
  retention_in_days = 14
  tags              = var.tags
}

data "aws_iam_policy_document" "metadata" {
  statement {
    actions   = ["s3:GetObject", "s3:GetObjectAttributes"]
    resources = ["${var.bucket_arn}/*"]
  }

  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.metadata.arn}:*"]
  }
}

resource "aws_iam_role_policy" "metadata" {
  role   = aws_iam_role.metadata.id
  policy = data.aws_iam_policy_document.metadata.json
}

resource "aws_lambda_function" "metadata" {
  function_name    = "${var.name}-metadata"
  role             = aws_iam_role.metadata.arn
  runtime          = "python3.14"
  handler          = "metadata.lambda_handler"
  filename         = data.archive_file.metadata.output_path
  source_code_hash = data.archive_file.metadata.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      S3_BUCKET = var.bucket_id
      ALB_DNS   = var.alb_dns_name
    }
  }

  depends_on = [aws_iam_role_policy.metadata]
  tags       = var.tags
}

resource "aws_lambda_permission" "s3" {
  statement_id   = "AllowS3Invoke"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.metadata.function_name
  principal      = "s3.amazonaws.com"
  source_arn     = var.bucket_arn
  source_account = var.source_account_id
}

resource "aws_s3_bucket_notification" "photos" {
  bucket = var.bucket_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.metadata.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.s3]
}
