


# Create the first Application Load Balancer
resource "aws_lb" "qa_load_balancer01" {
  name               = "Qa-LoadBalancer01"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]
  subnets            = [aws_subnet.public_subnets[0].id, aws_subnet.public_subnets[1].id]
  enable_deletion_protection = false

  tags = {
    Name = "Qa-LoadBalancer01"
  }
}

# Create the second Application Load Balancer  
resource "aws_lb" "qq_load_balancer02" {
  name               = "Qq-LoadBalancer02"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]
  subnets            = [aws_subnet.public_subnets[0].id, aws_subnet.public_subnets[1].id]

  enable_deletion_protection = false

  tags = {
    Name = "Qq-LoadBalancer02"
  }
}

# Create the ALB Security Group
resource "aws_security_group" "alb_security_group" {
  name   = "ALB Security Group"
  vpc_id = aws_vpc.non_prod_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_cloudwatch_log_group" "lb_log_group01" {
  name = "/aws/alb/${aws_lb.qa_load_balancer01.name}"
  retention_in_days = 7
  tags = {
        Environment = "QA"
        Project     = "qa_load_balancer01"
    }
}

resource "aws_cloudwatch_log_group" "lb_log_group02" {
  name = "/aws/alb/${aws_lb.qq_load_balancer02.name}"
  retention_in_days = 7
  tags = {
        Environment = "QA"
        Project     = "qq_load_balancer02"
    }
}
