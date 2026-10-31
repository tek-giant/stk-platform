data "terraform_remote_state" "data" {
  backend = "s3"
  config = {
    bucket  = "stk-tfstate-743978812281"
    key     = "dev/data/terraform.tfstate"
    region  = "eu-west-2"
    profile = "stk-platform"
  }
}

locals {
  data_subnet_ids = data.terraform_remote_state.network.outputs.data_subnet_ids
  db_endpoint     = data.terraform_remote_state.data.outputs.db_endpoint
  db_secret_arn   = data.terraform_remote_state.data.outputs.db_secret_arn
}

data "aws_subnet" "data" {
  for_each = toset(local.data_subnet_ids)
  id       = each.value
}

# The app may open connections to the data subnets on the PostgreSQL port only
resource "aws_vpc_security_group_egress_rule" "app_to_db" {
  for_each = data.aws_subnet.data

  security_group_id = aws_security_group.app.id
  description       = "PostgreSQL to the data tier subnets"
  cidr_ipv4         = each.value.cidr_block
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
}

# ECS reads the password at container start with the EXECUTION role and passes it in
data "aws_iam_policy_document" "read_db_secret" {
  statement {
    sid       = "ReadTheDatabasePasswordOnly"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [local.db_secret_arn]
  }
}

resource "aws_iam_role_policy" "execution_read_db_secret" {
  name   = "read-db-secret"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.read_db_secret.json
}
