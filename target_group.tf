resource "aws_autoscaling_attachment" "attachment" {
  autoscaling_group_name = aws_autoscaling_group.asg.id
  lb_target_group_arn    = aws_lb_target_group.tg.arn
}

# Add instances to a placmenet group with the spread option so they are across different hardware tenants
resource "aws_placement_group" "pg" {
  name         = "${var.group}-${var.project}"
  strategy     = "spread"
  spread_level = "rack"
}

resource "aws_lb_target_group" "tg" {
  name       = "${var.group}-${var.project}"
  port       = 80
  protocol   = "HTTP"
  vpc_id     = var.vpc_id
  slow_start = 90
  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = 8080
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }
}
