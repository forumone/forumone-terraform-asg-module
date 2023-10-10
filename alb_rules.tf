# this will create the host headers and route them to the proper target groups
# assuming the env.site.suffix names for non production (www) environments
# and adding any defined urls from the yaml definitions.
# This then divides that data into 5 host header chunks for the ALB rules
#
locals {
  assumed_urls = flatten([
    for name, site in local.mapped_sites : [
      for env in var.environments :
      "${env}.${site.name}.${var.suffix}"
      if env != "www" && site.env == env
    ]
  ])

  defined_urls = distinct(flatten([
    for env in var.environments : [
      for name, site in local.mapped_sites : [
        site.url
      ]
      if site.url != null && site.env == env
  ]]))

  target_group_routes = concat(local.defined_urls, local.assumed_urls)
  host_header_chunks  = chunklist(local.target_group_routes, 5)
}


# Get ALB information from Running Infrastructure
data "aws_lb" "alb" {
  name = var.alb_name
}
# Get the ALB HTTPS Listener arn
data "aws_lb_listener" "https" {
  load_balancer_arn = data.aws_lb.alb.arn
  port              = 443
}

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
