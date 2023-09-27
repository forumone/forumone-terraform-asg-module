data "aws_route53_zone" "public" {
  name = var.suffix
}

resource "aws_route53_record" "host" {
  for_each        = toset(local.all_env_urls)
  zone_id         = data.aws_route53_zone.public.zone_id
  name            = each.value
  type            = "A"
  allow_overwrite = true
  alias {
    name                   = data.aws_lb.alb.dns_name
    zone_id                = data.aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}
