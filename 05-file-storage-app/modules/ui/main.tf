resource "aws_security_group" "ui" {
  name        = "${var.name}-ui"
  description = "Public HTTP only"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_instance" "ui" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.ui.id]
  associate_public_ip_address = true

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
  }

  user_data_replace_on_change = true
  user_data = templatefile("${path.root}/user_data.sh.tftpl", {
    app     = file("${path.root}/app/app.py")
    api_url = var.api_url
    api_key = var.api_key
  })

  tags = merge(var.tags, {
    Name = "${var.name}-ui"
  })
}
