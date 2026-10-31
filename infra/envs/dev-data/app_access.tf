locals {
  app_subnet_ids = data.terraform_remote_state.network.outputs.app_subnet_ids
}

data "aws_subnet" "app" {
  for_each = toset(local.app_subnet_ids)
  id       = each.value
}

# First inbound rule on the database firewall: PostgreSQL port, from the app subnets only
resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  for_each = data.aws_subnet.app

  security_group_id = aws_security_group.db.id
  description       = "PostgreSQL from the app tier subnets"
  cidr_ipv4         = each.value.cidr_block
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
}
