data "terraform_remote_state" "dns" {
  backend = "s3"
  config = {
    bucket  = "stk-tfstate-743978812281"
    key     = "dev/network/terraform.tfstate"
    region  = "eu-west-2"
    profile = "stk-platform"
  }
}

locals {
  site_certificate_arn = data.terraform_remote_state.dns.outputs.site_certificate_arn
  route53_zone_id      = data.terraform_remote_state.dns.outputs.route53_zone_id
  site_name            = "stk.tek-giant.com"
}

# HTTPS from the internet to the public load balancer
resource "aws_vpc_security_group_ingress_rule" "alb_https_from_internet" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from the internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.public.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = local.site_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_route53_record" "site" {
  zone_id = local.route53_zone_id
  name    = local.site_name
  type    = "A"

  alias {
    name                   = aws_lb.public.dns_name
    zone_id                = aws_lb.public.zone_id
    evaluate_target_health = true
  }
}

output "site_url" {
  value = "https://${local.site_name}"
}
