# =================================================================================
# SECRETS MANAGER
# =================================================================================
# This file creates a random password and stores it securely in AWS Secrets Manager.
# This avoids ever having to write a password in our code or variables.
# =================================================================================


resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}


resource "aws_secretsmanager_secret" "db_password" {

  name = "fastapi/db_password_v2"
  tags = {
    Name = "Password for FastAPI RDS database"
  }
}


resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
  })
}
