# HTTPS certificate for the EKS copy of the site. The ECS site's certificate covers only
# stk.tek-giant.com, so eks.tek-giant.com needs its own. DNS proves we own the name.
data "aws_route53_zone" "main" {
  name = "tek-giant.com"
}

resource "aws_acm_certificate" "eks_site" {
  domain_name       = "eks.tek-giant.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "eks_site_cert_validation" {
  for_each = {
    for option in aws_acm_certificate.eks_site.domain_validation_options : option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  }

  zone_id         = data.aws_route53_zone.main.zone_id
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  allow_overwrite = true
}

# Waits until AWS has issued the certificate
resource "aws_acm_certificate_validation" "eks_site" {
  certificate_arn         = aws_acm_certificate.eks_site.arn
  validation_record_fqdns = [for record in aws_route53_record.eks_site_cert_validation : record.fqdn]
}

output "eks_site_certificate_arn" {
  description = "Put this in the Ingress in stk-gitops"
  value       = aws_acm_certificate_validation.eks_site.certificate_arn
}
