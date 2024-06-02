

# Log Group
resource "aws_cloudwatch_log_group" "ecs_logs" {
    name              = "aws/ecs/qa-cluster"
    retention_in_days = 30

    tags = {
        Environment = "QA"
        Project     = "ECS server"
    }
}

# ECS Cluster
resource "aws_ecs_cluster" "qa_cluster" {
  name = "QA-cluster"

  tags = {
    Environment = "QA"
    Project     = "ECS server"
  }
}

# Task Definition - auth
resource "aws_ecs_task_definition" "auth" {
  family                   = "auth"
  requires_compatibilities = ["EC2"]
  cpu                      = 256
  memory                   = 512
  network_mode             = "bridge"

  container_definitions = file("${path.module}/auth-task-definition/auth-task-definition.json")


#   container_definitions = <<DEFINITION
# [
#   {
#     "name": "auth",
#     "image": "your-auth-image:latest",
#     "essential": true,
#     "portMappings": [
#       {
#         "containerPort": 80,
#         "hostPort": 80
#       }
#     ]
#   }
# ]
# DEFINITION

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Environment = "QA"
    Project     = "ECS server"
  }
}

# Service - auth
resource "aws_ecs_service" "auth" {
  name            = "auth-service"
  cluster         = aws_ecs_cluster.qa_cluster.id
  task_definition = aws_ecs_task_definition.auth.arn
  desired_count   = 2
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = aws_lb_target_group.auth_tg.arn
    container_name   = "auth"
    container_port   = 80
  }

  tags = {
    Environment = "QA"
    Project     = "ECS server"
  }
}

# ALB, Listener, and Target Group
resource "aws_lb" "auth_alb" {
  name               = "auth-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.auth_alb_sg_ecs.id]
  subnets            = [aws_subnet.public_subnets[0].id, aws_subnet.public_subnets[1].id]

  tags = {
    Environment = "QA"
    Project     = "ECS server"
  }
}

# Rest of the resources...

# Service - payment
resource "aws_ecs_task_definition" "payment" {
  family                   = "payment"
  requires_compatibilities = ["EC2"]
  cpu                      = 256
  memory                   = 512
  network_mode             = "bridge"

  container_definitions = <<DEFINITION
[
  {
    "name": "payment",
    "image": "amazon/hello-world",
    "essential": true,
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ]
  }
]
DEFINITION

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Environment = "QA"
    Project     = "ECS server"
  }
}

resource "aws_ecs_service" "payment" {
  name            = "payment-service"
  cluster         = aws_ecs_cluster.qa_cluster.id
  task_definition = aws_ecs_task_definition.payment.arn
  desired_count   = 2
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = aws_lb_target_group.payment_tg.arn
    container_name   = "payment"
    container_port   = 80
  }

  tags = {
    Environment = "QA"
    Project     = "ECS server"
  }
}

# ECR Repositories
resource "aws_ecr_repository" "auth" {
  name = "auth"

  tags = {
    Environment = "QA"
    Project     = "ECS server"
  }
}

resource "aws_ecr_repository" "payment" {
  name = "payment"

  tags = {
    Environment = "QA"
    Project     = "ECS server"
  }
}

resource "aws_security_group" "auth_alb_sg_ecs" {
  name_prefix = "auth-alb-sg_ecs"
  vpc_id      = aws_vpc.non_prod_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "QA"
    Project     = "ECS server"
  }
}

resource "aws_lb_target_group" "auth_tg" {
  name        = "auth-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.non_prod_vpc.id
  target_type = "ip"

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Environment = "QA"
    Project     = "ECS server"
  }
}

resource "aws_lb_target_group" "payment_tg" {
  name        = "payment-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.non_prod_vpc.id
  target_type = "ip"

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Environment = "QA"
    Project     = "ECS server"
  }
}