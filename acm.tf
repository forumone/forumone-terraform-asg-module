locals {
  acm_chunks = chunklist(local.all_env_urls, 10)
}
module "sites_acm" {
  count                     = length(local.acm_chunks)
  source                    = "terraform-aws-modules/acm/aws"
  version                   = "~> 4.3"
  domain_name               = local.acm_chunks[count.index][0]
  zone_id                   = data.aws_route53_zone.public.zone_id
  validation_method         = "DNS"
  subject_alternative_names = slice(local.acm_chunks[count.index], 1, length(local.acm_chunks[count.index]))
}

resource "aws_lb_listener_certificate" "acm" {
  count           = length(local.acm_chunks)
  listener_arn    = data.aws_lb_listener.https.arn
  certificate_arn = module.sites_acm[count.index].acm_certificate_arn
}
