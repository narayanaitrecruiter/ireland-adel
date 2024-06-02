# RDS Security Group
resource "aws_security_group" "rds_security_group_mysql" {
  name   = "RDS Security Group for mysql"
  vpc_id = aws_vpc.non_prod_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
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
resource "aws_db_instance" "qa_mysql" {
  identifier           = "qa-mysql"
  engine               = "mysql"
  engine_version       = "5.7.34"
  instance_class      = "t3.small"
  allocated_storage   = 30
  storage_type         = "gp2"
  db_name             = "qa_mysql"
  username            = "var.mysqlusername"
  password            = "var.mysqlpassword"
  vpc_security_group_ids = [aws_security_group.rds_security_group_mysql.id]
  db_subnet_group_name = aws_db_subnet_group.qa_mysql_subnet_group.name
  backup_retention_period = 1
  backup_window           = "00:00-01:00"
  maintenance_window      = "Fri:00:00-Fri:03:00"
  auto_minor_version_upgrade = true

  tags = {
    Name = "qa-mysql"
  }
}


resource "aws_db_subnet_group" "qa_mysql_subnet_group" {
  name        = "qa-postgres-subnet-group"
  subnet_ids  = [aws_subnet.public_subnets[0].id, aws_subnet.public_subnets[1].id]
  description = "Subnet group for QA Aurora Postgres"
}

# IAM Role (if needed)
resource "aws_iam_role" "rds_access_role_mysql" {
  name = "rds-access-role_mysql"

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
resource "aws_cloudwatch_log_group" "mysql_log_group" {
  name              = "/aws/rds/qa-mysql"
  retention_in_days = 30
  tags = {
        Environment = "QA"
        Project     = "qa_mysql"
    }
}