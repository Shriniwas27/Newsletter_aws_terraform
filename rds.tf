# =================================================================================
# DATABASE (RDS)
# =================================================================================
# This file provisions the managed PostgreSQL database using RDS. It creates a
# subnet group to place the database in our private subnets, then creates a
# primary DB instance and a read replica in a different AZ for high availability.
# =================================================================================


resource "aws_db_subnet_group" "main" {
  name       = "fastapi-db-subnet-group"
  subnet_ids = [for subnet in aws_subnet.private : subnet.id]

  tags = {
    Name = "FastAPI DB Subnet Group"
  }
}


resource "aws_db_instance" "primary" {
  identifier                = "fastapi-db-primary"
  allocated_storage         = 20
  storage_type              = "gp2"
  engine                    = "postgres"
  engine_version            = "16.3"
  instance_class            = var.db_instance_class
  db_name                   = var.db_name
  username                  = var.db_username
  password                  = random_password.db_password.result
  db_subnet_group_name      = aws_db_subnet_group.main.name
  vpc_security_group_ids    = [aws_security_group.rds.id]
  multi_az                  = false
  publicly_accessible       = false
  skip_final_snapshot       = true
  backup_retention_period   = 7
  apply_immediately         = true
}


resource "aws_db_instance" "replica" {
  identifier           = "fastapi-db-replica"
  replicate_source_db  = aws_db_instance.primary.identifier
  instance_class       = var.db_instance_class
  skip_final_snapshot  = true
  publicly_accessible  = false
  
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "fastapi-db-replica"
  }
}
