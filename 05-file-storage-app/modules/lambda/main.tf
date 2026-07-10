data "archive_file" "api" {
  type        = "zip"
  source_file = "${path.root}/lambda/api.py"
  output_path = "${path.root}/lambda/api.zip"
}

data "archive_file" "metadata" {
  type        = "zip"
  source_file = "${path.root}/lambda/metadata.py"
  output_path = "${path.root}/lambda/metadata.zip"
}

data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "api" {
  name               = "${var.name}-api"
  assume_role_policy = data.aws_iam_policy_document.trust.json
  tags               = var.tags
}

resource "aws_iam_role" "metadata" {
  name               = "${var.name}-metadata"
  assume_role_policy = data.aws_iam_policy_document.trust.json
  tags               = var.tags
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/lambda/${var.name}-api"
  retention_in_days = 14
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "metadata" {
  name              = "/aws/lambda/${var.name}-metadata"
  retention_in_days = 14
  tags              = var.tags
}

data "aws_iam_policy_document" "api" {
  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${var.bucket_arn}/*"]
  }

  statement {
    actions   = ["dynamodb:Scan", "dynamodb:DeleteItem"]
    resources = [var.metadata_table_arn]
  }

  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.api.arn}:*"]
  }
}

data "aws_iam_policy_document" "metadata" {
  statement {
    actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
    resources = [var.queue_arn]
  }

  statement {
    actions   = ["dynamodb:PutItem"]
    resources = [var.metadata_table_arn]
  }

  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.metadata.arn}:*"]
  }
}

resource "aws_iam_role_policy" "api" {
  role   = aws_iam_role.api.id
  policy = data.aws_iam_policy_document.api.json
}

resource "aws_iam_role_policy" "metadata" {
  role   = aws_iam_role.metadata.id
  policy = data.aws_iam_policy_document.metadata.json
}

resource "aws_lambda_function" "api" {
  function_name    = "${var.name}-api"
  role             = aws_iam_role.api.arn
  runtime          = "python3.14"
  handler          = "api.lambda_handler"
  filename         = data.archive_file.api.output_path
  source_code_hash = data.archive_file.api.output_base64sha256
  timeout          = 15

  environment {
    variables = {
      BUCKET     = var.bucket_id
      TABLE_NAME = var.metadata_table
    }
  }

  depends_on = [aws_iam_role_policy.api]
  tags       = var.tags
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
      TABLE_NAME = var.metadata_table
    }
  }

  depends_on = [aws_iam_role_policy.metadata]
  tags       = var.tags
}

resource "aws_lambda_event_source_mapping" "metadata" {
  event_source_arn        = var.queue_arn
  function_name           = aws_lambda_function.metadata.arn
  batch_size              = 10
  function_response_types = ["ReportBatchItemFailures"]
}
