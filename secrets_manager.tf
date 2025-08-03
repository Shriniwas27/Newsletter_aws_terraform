# =================================================================================
# SECRETS MANAGER
# =================================================================================
# This file creates a random password and stores it securely in AWS Secrets Manager.
# This avoids ever having to write a password in our code or variables.
# =================================================================================

# Generate a random password for the database.
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Create a secret in Secrets Manager to store the random password.
resource "aws_secretsmanager_secret" "db_password" {
  # --- THIS IS THE FIX ---
  # We are using a new name to avoid the conflict with the secret pending deletion.
  name = "fastapi/db_password_v2"
  tags = {
    Name = "Password for FastAPI RDS database"
  }
}

# Put the generated random password into the secret as a JSON object.
# Storing it as a JSON object is a best practice.
resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
  })
}