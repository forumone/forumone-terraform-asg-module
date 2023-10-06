resource "aws_lb_listener_rule" "lb_routes" {
  count = length(local.host_header_chunks)

  listener_arn = data.aws_lb_listener.https.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

  condition {
    host_header {
      values = local.host_header_chunks[count.index]
    }
  }
  tags = {
    Name = "${var.group_name}-${count.index}"
  }
}
