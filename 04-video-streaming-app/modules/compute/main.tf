data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "worker" {
  name               = "${var.name}-worker"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
  tags               = var.tags
}

resource "aws_iam_role" "web" {
  name               = "${var.name}-web"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
  tags               = var.tags
}

data "aws_iam_policy_document" "worker" {
  statement {
    actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:ChangeMessageVisibility", "sqs:GetQueueAttributes"]
    resources = [var.queue_arn]
  }

  statement {
    actions   = ["s3:GetObject"]
    resources = ["${var.input_bucket_arn}/*"]
  }

  statement {
    actions   = ["s3:PutObject"]
    resources = ["${var.output_bucket_arn}/*"]
  }

  statement {
    actions   = ["dynamodb:PutItem", "dynamodb:UpdateItem"]
    resources = [var.catalog_table_arn]
  }

  statement {
    actions   = ["ssm:UpdateInstanceInformation", "ssmmessages:CreateControlChannel", "ssmmessages:CreateDataChannel", "ssmmessages:OpenControlChannel", "ssmmessages:OpenDataChannel"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "web" {
  statement {
    actions   = ["s3:PutObject"]
    resources = ["${var.input_bucket_arn}/*"]
  }

  statement {
    actions   = ["s3:GetObject", "s3:DeleteObject"]
    resources = ["${var.output_bucket_arn}/*"]
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [var.output_bucket_arn]
  }

  statement {
    actions   = ["dynamodb:Scan", "dynamodb:PutItem", "dynamodb:DeleteItem"]
    resources = [var.catalog_table_arn]
  }

  statement {
    actions   = ["ssm:UpdateInstanceInformation", "ssmmessages:CreateControlChannel", "ssmmessages:CreateDataChannel", "ssmmessages:OpenControlChannel", "ssmmessages:OpenDataChannel"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "worker" {
  role   = aws_iam_role.worker.id
  policy = data.aws_iam_policy_document.worker.json
}

resource "aws_iam_role_policy" "web" {
  role   = aws_iam_role.web.id
  policy = data.aws_iam_policy_document.web.json
}

resource "aws_iam_instance_profile" "worker" {
  name = "${var.name}-worker"
  role = aws_iam_role.worker.name
}

resource "aws_iam_instance_profile" "web" {
  name = "${var.name}-web"
  role = aws_iam_role.web.name
}

resource "aws_instance" "worker" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [var.worker_security_group_id]
  iam_instance_profile        = aws_iam_instance_profile.worker.name

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted   = true
    volume_size = 20
    volume_type = "gp3"
  }

  user_data_replace_on_change = true
  user_data = templatefile("${path.root}/worker_user_data.sh.tftpl", {
    worker = file("${path.root}/app/worker.py")
    input  = var.input_bucket_id
    output = var.output_bucket_id
    queue  = var.queue_url
    table  = var.catalog_table_name
    region = var.aws_region
  })

  tags = merge(var.tags, { Name = "${var.name}-worker" })
}

resource "aws_instance" "web" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [var.web_security_group_id]
  iam_instance_profile        = aws_iam_instance_profile.web.name

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
  }

  user_data_replace_on_change = true
  user_data = templatefile("${path.root}/web_user_data.sh.tftpl", {
    app    = file("${path.root}/app/server.py")
    input  = var.input_bucket_id
    output = var.output_bucket_id
    table  = var.catalog_table_name
    region = var.aws_region
  })

  tags = merge(var.tags, { Name = "${var.name}-web" })
}
