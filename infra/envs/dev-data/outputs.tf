output "db_identifier" {
  value = aws_db_instance.main.identifier
}

output "db_endpoint" {
  value = aws_db_instance.main.address
}

output "db_secret_arn" {
  description = "Where RDS keeps the generated master password"
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}
