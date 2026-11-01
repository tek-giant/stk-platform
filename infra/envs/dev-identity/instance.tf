data "aws_ssm_parameter" "windows_ami" {
  name = "/aws/service/ami-windows-latest/Windows_Server-2022-English-Full-Base"
}

data "aws_iam_policy_document" "assume_ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "dc" {
  name               = "${local.name}-dc"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
}

resource "aws_iam_role_policy_attachment" "dc_ssm" {
  role       = aws_iam_role.dc.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "dc" {
  name = "${local.name}-dc"
  role = aws_iam_role.dc.name
}

# No inbound rules: access is through Systems Manager only.
resource "aws_security_group" "dc" {
  name        = "${local.name}-dc"
  description = "Domain controller: no inbound, all outbound"
  vpc_id      = local.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "dc_all" {
  security_group_id = aws_security_group.dc.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Outbound for SSM, updates and AD tools (needs the NAT)"
}

resource "aws_instance" "dc" {
  ami                         = data.aws_ssm_parameter.windows_ami.value
  instance_type               = "t3.medium"
  subnet_id                   = local.app_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.dc.id]
  iam_instance_profile        = aws_iam_instance_profile.dc.name
  associate_public_ip_address = false

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    encrypted   = true
    kms_key_id  = local.kms_key_arn
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = "${local.name}-dc"
  }
}

resource "random_password" "safe_mode" {
  length           = 24
  special          = true
  override_special = "!#%*-_=+"
}

resource "aws_secretsmanager_secret" "dc_admin" {
  name                    = "${local.name}/dc-admin-password"
  kms_key_id              = local.kms_key_arn
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "dc_admin" {
  secret_id     = aws_secretsmanager_secret.dc_admin.id
  secret_string = random_password.safe_mode.result
}

output "dc_instance_id" {
  value = aws_instance.dc.id
}

output "dc_secret_arn" {
  value = aws_secretsmanager_secret.dc_admin.arn
}