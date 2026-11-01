# The public DNS zone for the domain. Deleting it would break everything that resolves under
# tek-giant.com, so Terraform is told never to destroy it.
resource "aws_route53_zone" "main" {
  name = "tek-giant.com"

  lifecycle {
    prevent_destroy = true
  }
}

# Certificate for the site's address, proved by a DNS record rather than by email
resource "aws_acm_certificate" "site" {
  domain_name       = "stk.tek-giant.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for option in aws_acm_certificate.site.domain_validation_options : option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  }

  zone_id         = aws_route53_zone.main.zone_id
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  allow_overwrite = true
}

# Waits until the certificate is issued
resource "aws_acm_certificate_validation" "site" {
  certificate_arn         = aws_acm_certificate.site.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

output "route53_nameservers" {
  description = "Set these as the domain's name servers at the registrar"
  value       = aws_route53_zone.main.name_servers
}

output "route53_zone_id" {
  value = aws_route53_zone.main.zone_id
}

output "site_certificate_arn" {
  value = aws_acm_certificate.site.arn
}
