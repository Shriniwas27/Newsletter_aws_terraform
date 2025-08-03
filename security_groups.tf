# =================================================================================
# SECURITY GROUPS (FIREWALL RULES)
# =================================================================================
# This file defines the security groups, which act as virtual firewalls for our
# resources. We create separate groups for the ALB, EC2 instances, and the RDS
# database to enforce the principle of least privilege.
# =================================================================================


data "aws_ip_ranges" "ec2_instance_connect" {
  regions  = [var.aws_region]
  services = ["ec2_instance_connect"]
}


resource "aws_security_group" "alb" {
  name        = "fastapi-alb-sg"
  description = "Allow HTTP/HTTPS traffic to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fastapi-alb-sg"
  }
}


resource "aws_security_group" "ec2" {
  name        = "fastapi-ec2-sg"
  description = "Allow traffic from ALB and SSH for EC2 Instance Connect"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "FastAPI traffic from ALB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # --- THIS IS THE FIX ---
  # Add a rule to allow SSH (port 22) only from the EC2 Instance Connect service IPs.
  ingress {
    description = "SSH for EC2 Instance Connect"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = data.aws_ip_ranges.ec2_instance_connect.cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fastapi-ec2-sg"
  }
}


resource "aws_security_group" "rds" {
  name        = "fastapi-rds-sg"
  description = "Allow traffic from EC2 instances to RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fastapi-rds-sg"
  }
}
