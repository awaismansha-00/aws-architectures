resource "aws_lb_target_group" "web" {
  for_each = var.instance_ids

  name     = substr("${var.name}-${each.key}", 0, 32)
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path    = "/"
    matcher = "200"
  }

  tags = var.tags
}

resource "aws_lb_target_group_attachment" "web" {
  for_each = var.instance_ids

  target_group_arn = aws_lb_target_group.web[each.key].arn
  target_id        = each.value
  port             = 80
}

resource "aws_lb" "this" {
  name                       = substr("${var.name}-alb", 0, 32)
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.alb_security_group_id]
  subnets                    = var.public_subnet_ids
  enable_deletion_protection = false
  tags                       = var.tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.web["blue"].arn
        weight = 100 - var.green_traffic_weight
      }

      target_group {
        arn    = aws_lb_target_group.web["green"].arn
        weight = var.green_traffic_weight
      }
    }
  }
}
