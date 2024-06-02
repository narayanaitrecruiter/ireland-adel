

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "aurora_log_group" {
  name              = "/aws/rds/cluster/${aws_rds_cluster.qa_postgres.id}/error"
  retention_in_days = 30
  tags = {
        Environment = "QA"
        Project     = "Aurora server"
    }
}

# RDS Security Group
resource "aws_security_group" "rds_security_group_aurora" {
  name   = "RDS Security Group for Aurora"
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

# RDS Cluster
resource "aws_rds_cluster" "qa_postgres" {
  cluster_identifier      = "qa-postgres"
  engine                  = "aurora-postgresql"
  engine_version          = "11.10"
  availability_zones      = var.availability_zones
  database_name           = "qa_postgres"
  master_username         = var.aurorausername
  master_password         = var.aurorapassword
  backup_retention_period = 1
  preferred_backup_window = "00:00-01:00"
  vpc_security_group_ids   = [aws_security_group.rds_security_group_aurora.id]
  db_subnet_group_name    = aws_db_subnet_group.qa_aurora_subnet_group.name
  engine_mode              = "serverless"
  scaling_configuration {
    auto_pause               = true
    max_capacity             = 1
    min_capacity             = 1
    seconds_until_auto_pause = 300
  }
  tags = {
    Name = "qa-postgres"
  }
}

resource "aws_db_subnet_group" "qa_aurora_subnet_group" {
  name        = "qa-postgres-subnet-group"
  subnet_ids  = [aws_subnet.public_subnets[0].id, aws_subnet.public_subnets[1].id]
  description = "Subnet group for QA Aurora Postgres"
}

# IAM Role (if needed)
resource "aws_iam_role" "rds_access_role" {
  name = "rds-access-role"

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
