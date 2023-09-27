data "aws_lb" "alb" {
  name = var.alb_name
}

data "aws_lb_listener" "https" {
  load_balancer_arn = data.aws_lb.alb.arn
  port              = 443
}
