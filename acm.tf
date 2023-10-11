# This will create a list of SSL records to create
# this will check the create_ssl flag for each site
# this will also check the create_certificates flag for the ASG stack
locals {
  ssl_certs = distinct(flatten([
    for env in var.environments : [
      for name, site in local.mapped_sites : [
        "${env}.${site.name}.${var.suffix}"
      ]
      if site.env == env && site.create_ssl != false
    ]
    if var.create_ssl_certificates != false
  ]))
  # divide list into chunks because of ACM limits.
  acm_chunks = chunklist(local.ssl_certs, 10)
}

module "sites_acm" {
  count   = length(local.acm_chunks)
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.3"
  # This takes the first index from the chunked list and uses it for the SSL name
  domain_name       = local.acm_chunks[count.index][0]
  zone_id           = data.aws_route53_zone.public.zone_id
  validation_method = "DNS"
  # This uses the rest of the list as SAN's excluding the first index
  subject_alternative_names = slice(local.acm_chunks[count.index], 1, length(local.acm_chunks[count.index]))
}

resource "aws_lb_listener_certificate" "acm" {
  count           = length(local.acm_chunks)
  listener_arn    = data.aws_lb_listener.https.arn
  certificate_arn = module.sites_acm[count.index].acm_certificate_arn
}
