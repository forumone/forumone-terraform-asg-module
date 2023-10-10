# This will create a list of route 53 records to create
# this will check the create_route53 flag for each site
# this will also check the create_route53_records flag for the ASG stack

locals {
  route53_records = distinct(flatten([
    for env in var.environments : [
      for name, site in local.mapped_sites : [
        "${env}.${site.name}.${var.suffix}"
      ]
      if site.env == env && site.create_route53 != false
    ]
    if var.create_route53_records != false
  ]))
}

# This will retreive the zone id for the specified suffix
data "aws_route53_zone" "public" {
  name = var.suffix
}

# This will create an aname alias for each site and point it
# To the ALB
resource "aws_route53_record" "host" {
  for_each        = toset(local.route53_records)
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
