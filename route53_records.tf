data "aws_route53_zone" "public" {
  name = var.suffix
}

resource "aws_route53_record" "host" {
  count           = var.create_route53_records ? length(local.all_env_urls) : 0
  zone_id         = data.aws_route53_zone.public.zone_id
  name            = count.index
  type            = "A"
  allow_overwrite = true
  alias {
    name                   = data.aws_lb.alb.dns_name
    zone_id                = data.aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}
