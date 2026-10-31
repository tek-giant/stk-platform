resource "aws_security_group" "alb" {
  name        = "${local.name}-public-alb"
  description = "Public load balancer: HTTP from the internet, forwards to the web servers"
  vpc_id      = local.vpc_id

  tags = { Name = "${local.name}-public-alb-sg" }
}

resource "aws_security_group" "web" {
  name        = "${local.name}-web"
  description = "Web servers: port 8080 from the public load balancer only"
  vpc_id      = local.vpc_id

  tags = { Name = "${local.name}-web-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_from_internet" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from the internet"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_web" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward to the web servers"
  referenced_security_group_id = aws_security_group.web.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "web_from_alb" {
  security_group_id            = aws_security_group.web.id
  description                  = "Web port from the public load balancer only"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "web_https_out" {
  security_group_id = aws_security_group.web.id
  description       = "HTTPS out: install packages, pull the image, Systems Manager"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "web_to_internal_alb" {
  security_group_id = aws_security_group.web.id
  description       = "HTTP to the internal load balancer, inside the VPC only"
  cidr_ipv4         = data.aws_vpc.main.cidr_block
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}
