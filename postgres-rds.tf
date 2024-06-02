

# Retrieve the VPC and Subnet IDs


# RDS Security Group
resource "aws_security_group" "rds_security_group_postgres" {
  name   = "RDS Security Group for postgres"
  vpc_id = aws_vpc.non_prod_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS Instance
resource "aws_db_instance" "qa_postgres_rds" {
  identifier           = "qa-postgres-rds"
  engine               = "postgres"
  engine_version       = "13.7"
  instance_class      = "t3.small"
  allocated_storage   = 30
  storage_type         = "gp2"
  db_name             = "qa_postgres"
  username            = "var.postgresusername"
  password            = "var.postgrespassword"
  vpc_security_group_ids = [aws_security_group.rds_security_group_postgres.id]
  db_subnet_group_name = aws_db_subnet_group.qa_postgres_subnet_group.name
  backup_retention_period = 1
  backup_window           = "00:00-01:00"
  maintenance_window      = "Fri:00:00-Fri:03:00"
  auto_minor_version_upgrade = true

  tags = {
    Name = "qa-postgres-rds"
  }
}


resource "aws_db_subnet_group" "qa_postgres_subnet_group" {
  name        = "qa-postgres-subnet-group"
  subnet_ids  = [aws_subnet.public_subnets[0].id, aws_subnet.public_subnets[1].id]
  description = "Subnet group for QA Aurora Postgres"
}
# IAM Role (if needed)
resource "aws_iam_role" "rds_access_role_postgres" {
  name = "rds-access-role_postgres"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "rds.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "postgres_log_group" {
  name              = "/aws/rds/qa-postgres-rds"
  retention_in_days = 30
  tags = {
        Environment = "QA"
        Project     = "qa-postgres-rds"
    }
}