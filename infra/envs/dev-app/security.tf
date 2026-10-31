resource "aws_security_group" "alb" {
  name        = "${local.name}-internal-alb"
  description = "Internal load balancer: HTTP from inside the VPC, forwards to the app"
  vpc_id      = local.vpc_id

  tags = { Name = "${local.name}-internal-alb-sg" }
}

resource "aws_security_group" "app" {
  name        = "${local.name}-app"
  description = "App containers: port 8080 from the internal load balancer only"
  vpc_id      = local.vpc_id

  tags = { Name = "${local.name}-app-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http_from_vpc" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from inside the VPC"
  cidr_ipv4         = data.aws_vpc.main.cidr_block
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward to the app containers"
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "App port from the internal load balancer only"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "app_https_out" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS out: pull the image from ECR and send logs"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}
