data "archive_file" "handler" {
  type        = "zip"
  source_file = "${path.root}/lambda/handler.py"
  output_path = "${path.root}/lambda/handler.zip"
}

data "archive_file" "archiver" {
  type        = "zip"
  source_file = "${path.root}/lambda/archiver.py"
  output_path = "${path.root}/lambda/archiver.zip"
}

data "archive_file" "authorizer" {
  type        = "zip"
  source_file = "${path.root}/lambda/authorizer.py"
  output_path = "${path.root}/lambda/authorizer.zip"
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

resource "aws_iam_role" "handler" {
  name               = "${var.name}-handler"
  assume_role_policy = data.aws_iam_policy_document.trust.json
  tags               = var.tags
}

resource "aws_iam_role" "archiver" {
  name               = "${var.name}-archiver"
  assume_role_policy = data.aws_iam_policy_document.trust.json
  tags               = var.tags
}

resource "aws_iam_role" "authorizer" {
  name               = "${var.name}-authorizer"
  assume_role_policy = data.aws_iam_policy_document.trust.json
  tags               = var.tags
}

resource "aws_cloudwatch_log_group" "lambda" {
  for_each          = toset(["handler", "archiver", "authorizer"])
  name              = "/aws/lambda/${var.name}-${each.key}"
  retention_in_days = 14
  tags              = var.tags
}

data "aws_iam_policy_document" "handler" {
  statement {
    actions   = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:UpdateItem", "dynamodb:DeleteItem", "dynamodb:Scan"]
    resources = [var.connections_table_arn]
  }

  statement {
    actions   = ["sqs:SendMessage"]
    resources = [var.queue_arn]
  }

  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.lambda["handler"].arn}:*"]
  }
}

data "aws_iam_policy_document" "archiver" {
  statement {
    actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
    resources = [var.queue_arn]
  }

  statement {
    actions   = ["dynamodb:PutItem"]
    resources = [var.history_table_arn]
  }

  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.lambda["archiver"].arn}:*"]
  }
}

data "aws_iam_policy_document" "authorizer" {
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.lambda["authorizer"].arn}:*"]
  }
}

resource "aws_iam_role_policy" "handler" {
  role   = aws_iam_role.handler.id
  policy = data.aws_iam_policy_document.handler.json
}

resource "aws_iam_role_policy" "archiver" {
  role   = aws_iam_role.archiver.id
  policy = data.aws_iam_policy_document.archiver.json
}

resource "aws_iam_role_policy" "authorizer" {
  role   = aws_iam_role.authorizer.id
  policy = data.aws_iam_policy_document.authorizer.json
}

resource "aws_lambda_function" "handler" {
  function_name    = "${var.name}-handler"
  role             = aws_iam_role.handler.arn
  runtime          = "python3.14"
  handler          = "handler.lambda_handler"
  filename         = data.archive_file.handler.output_path
  source_code_hash = data.archive_file.handler.output_base64sha256
  timeout          = 15

  environment {
    variables = {
      ACTIVE_TABLE  = var.connections_table
      SQS_QUEUE_URL = var.queue_url
    }
  }

  depends_on = [aws_iam_role_policy.handler]
  tags       = var.tags
}

resource "aws_lambda_function" "archiver" {
  function_name    = "${var.name}-archiver"
  role             = aws_iam_role.archiver.arn
  runtime          = "python3.14"
  handler          = "archiver.lambda_handler"
  filename         = data.archive_file.archiver.output_path
  source_code_hash = data.archive_file.archiver.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      HISTORY_TABLE = var.history_table
    }
  }

  depends_on = [aws_iam_role_policy.archiver]
  tags       = var.tags
}

resource "aws_lambda_function" "authorizer" {
  function_name    = "${var.name}-authorizer"
  role             = aws_iam_role.authorizer.arn
  runtime          = "python3.14"
  handler          = "authorizer.lambda_handler"
  filename         = data.archive_file.authorizer.output_path
  source_code_hash = data.archive_file.authorizer.output_base64sha256
  timeout          = 5

  environment {
    variables = {
      CONNECTION_TOKEN = var.connection_token
    }
  }

  depends_on = [aws_iam_role_policy.authorizer]
  tags       = var.tags
}

resource "aws_lambda_event_source_mapping" "archive" {
  event_source_arn        = var.queue_arn
  function_name           = aws_lambda_function.archiver.arn
  batch_size              = 10
  function_response_types = ["ReportBatchItemFailures"]
}
