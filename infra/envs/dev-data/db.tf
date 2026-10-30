resource "aws_db_subnet_group" "main" {
  name       = "${local.name}-db"
  subnet_ids = local.data_subnet_ids

  tags = { Name = "${local.name}-db-subnets" }
}

# No inbound rules yet: the app tier does not exist. Add a rule from its
# security group when it is built. With no rules, nothing can connect.
resource "aws_security_group" "db" {
  name        = "${local.name}-db"
  description = "Database access, no inbound rules until the app tier exists"
  vpc_id      = local.vpc_id

  tags = { Name = "${local.name}-db-sg" }
}

resource "aws_db_instance" "main" {
  identifier = "${local.name}-db"

  engine         = "postgres"
  engine_version = "16"
  instance_class = "db.t4g.micro"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true
  kms_key_id        = local.kms_key_arn

  db_name  = "stock"
  username = "stk_admin"

  # RDS generates the password and keeps it in Secrets Manager.
  # It never appears in this code or in Git.
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period             = 7
  copy_tags_to_snapshot               = true
  auto_minor_version_upgrade          = true
  iam_database_authentication_enabled = true

  # Dev choices so the database can be destroyed after each session.
  # For prod: deletion_protection = true and skip_final_snapshot = false.
  deletion_protection = false
  skip_final_snapshot = true

  tags = { Name = "${local.name}-db" }
}
