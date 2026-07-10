resource "aws_sqs_queue" "dlq" {
  name                      = "${var.name}-dlq"
  sqs_managed_sse_enabled   = true
  message_retention_seconds = 1209600
  tags                      = var.tags
}

resource "aws_sqs_queue" "events" {
  name                       = "${var.name}-events"
  sqs_managed_sse_enabled    = true
  visibility_timeout_seconds = 60

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })

  tags = var.tags
}

data "aws_iam_policy_document" "queue" {
  statement {
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.events.arn]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [var.bucket_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.source_account_id]
    }
  }
}

resource "aws_sqs_queue_policy" "events" {
  queue_url = aws_sqs_queue.events.id
  policy    = data.aws_iam_policy_document.queue.json
}

resource "aws_s3_bucket_notification" "events" {
  bucket = var.bucket_id

  queue {
    queue_arn = aws_sqs_queue.events.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sqs_queue_policy.events]
}
