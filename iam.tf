# =================================================================================
# IDENTITY & ACCESS MANAGEMENT (IAM)
# =================================================================================
# This file creates the necessary IAM Role and Policies to allow our EC2 instances
# to securely interact with other AWS services like Secrets Manager and CloudWatch
# without needing hardcoded credentials.
# =================================================================================

# Create an IAM Role that EC2 instances can assume.
resource "aws_iam_role" "ec2_role" {
  name = "fastapi-ec2-role"

  # This policy allows EC2 instances to assume this role.
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "Role for FastAPI EC2 Instances"
  }
}

# --- Policy for CloudWatch ---
# This policy grants permission to create and write to log streams.
resource "aws_iam_policy" "cloudwatch_policy" {
  name        = "fastapi-cloudwatch-policy"
  description = "Allows EC2 instances to push logs to CloudWatch"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach the CloudWatch policy to our EC2 role.
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.cloudwatch_policy.arn
}


# --- Policy for Secrets Manager ---
# This policy grants permission to read the specific secret containing the DB password.
resource "aws_iam_policy" "secrets_manager_policy" {
  name        = "fastapi-secrets-manager-policy"
  description = "Allows EC2 instances to read the DB password from Secrets Manager"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action   = "secretsmanager:GetSecretValue",
        Effect   = "Allow",
        Resource = aws_secretsmanager_secret.db_password.arn
      }
    ]
  })
}

# Attach the Secrets Manager policy to our EC2 role.
resource "aws_iam_role_policy_attachment" "secrets_manager" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}


# --- Instance Profile ---
# The instance profile is a container for the IAM role that we can attach to an EC2 instance.
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "fastapi-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}