locals {
  versions = {
    blue = {
      subnet = 0
      color  = "blue"
      label  = "VERSION 1 (BLUE)"
    }
    green = {
      subnet = 1
      color  = "green"
      label  = "VERSION 2 (GREEN)"
    }
  }
}

data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ssm" {
  statement {
    actions = [
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "web" {
  name               = "${var.name}-web"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "ssm" {
  role   = aws_iam_role.web.id
  policy = data.aws_iam_policy_document.ssm.json
}

resource "aws_iam_instance_profile" "web" {
  name = "${var.name}-web"
  role = aws_iam_role.web.name
}

resource "aws_instance" "web" {
  for_each = local.versions

  ami                    = var.ami_id
  instance_type          = var.instance_type
  iam_instance_profile   = aws_iam_instance_profile.web.name
  subnet_id              = var.subnet_ids[each.value.subnet]
  vpc_security_group_ids = [var.security_group_id]

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
  }

  user_data_replace_on_change = true

  user_data = <<-EOT
    #!/bin/bash
    set -euxo pipefail
    dnf install -y httpd
    cat > /var/www/html/index.html <<'HTML'
    <html><body
style="background:${each.value.color};color:white"><h1>${each.value.label}</h1></body></html>
    HTML
    systemctl enable --now httpd
  EOT

  tags = merge(var.tags, {
    Name = "${var.name}-${each.key}"
  })
}
