data "archive_file" "create" {
  type        = "zip"
  source_file = "${path.root}/lambda/create.py"
  output_path = "${path.root}/lambda/create.zip"
}

data "archive_file" "redirect" {
  type        = "zip"
  source_file = "${path.root}/lambda/redirect.py"
  output_path = "${path.root}/lambda/redirect.zip"
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

resource "aws_iam_role" "create" {
  name               = "${var.name}-create"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
  tags               = var.tags
}

resource "aws_iam_role" "redirect" {
  name               = "${var.name}-redirect"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
  tags               = var.tags
}

resource "aws_cloudwatch_log_group" "create" {
  name              = "/aws/lambda/${var.name}-create"
  retention_in_days = 14
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "redirect" {
  name              = "/aws/lambda/${var.name}-redirect"
  retention_in_days = 14
  tags              = var.tags
}

data "aws_iam_policy_document" "create" {
  statement {
    sid       = "WriteUrl"
    actions   = ["dynamodb:PutItem"]
    resources = [var.table_arn]
  }

  statement {
    sid       = "Logs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.create.arn}:*"]
  }
}

data "aws_iam_policy_document" "redirect" {
  statement {
    sid       = "ReadUrl"
    actions   = ["dynamodb:GetItem"]
    resources = [var.table_arn]
  }

  statement {
    sid       = "Logs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.redirect.arn}:*"]
  }
}

resource "aws_iam_role_policy" "create" {
  role   = aws_iam_role.create.id
  policy = data.aws_iam_policy_document.create.json
}

resource "aws_iam_role_policy" "redirect" {
  role   = aws_iam_role.redirect.id
  policy = data.aws_iam_policy_document.redirect.json
}

resource "aws_lambda_function" "create" {
  function_name    = "${var.name}-create"
  role             = aws_iam_role.create.arn
  runtime          = "python3.14"
  handler          = "create.lambda_handler"
  filename         = data.archive_file.create.output_path
  source_code_hash = data.archive_file.create.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      TABLE_NAME = var.table_name
    }
  }

  depends_on = [aws_iam_role_policy.create, aws_cloudwatch_log_group.create]
  tags       = var.tags
}

resource "aws_lambda_function" "redirect" {
  function_name    = "${var.name}-redirect"
  role             = aws_iam_role.redirect.arn
  runtime          = "python3.14"
  handler          = "redirect.lambda_handler"
  filename         = data.archive_file.redirect.output_path
  source_code_hash = data.archive_file.redirect.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      TABLE_NAME = var.table_name
    }
  }

  depends_on = [aws_iam_role_policy.redirect, aws_cloudwatch_log_group.redirect]
  tags       = var.tags
}
