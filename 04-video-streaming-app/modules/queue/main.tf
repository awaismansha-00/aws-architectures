resource "aws_sqs_queue" "dlq" {
  name                      = "${var.name}-dlq"
  sqs_managed_sse_enabled   = true
  message_retention_seconds = 1209600
  tags                      = var.tags
}

resource "aws_sqs_queue" "video" {
  name                       = "${var.name}-queue"
  sqs_managed_sse_enabled    = true
  visibility_timeout_seconds = 900
  redrive_policy             = jsonencode({ deadLetterTargetArn = aws_sqs_queue.dlq.arn, maxReceiveCount = 5 })
  tags                       = var.tags
}

data "aws_iam_policy_document" "queue" {
  statement {
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.video.arn]

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [var.input_bucket_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.source_account_id]
    }
  }
}

resource "aws_sqs_queue_policy" "video" {
  queue_url = aws_sqs_queue.video.id
  policy    = data.aws_iam_policy_document.queue.json
}

resource "aws_s3_bucket_notification" "input" {
  bucket = var.input_bucket_id

  queue {
    queue_arn = aws_sqs_queue.video.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_sqs_queue_policy.video]
}
