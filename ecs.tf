

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
  security_groups    = [aws_security_group.ecs_sg.id]
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

resource "aws_security_group" "ecs_sg" {
  name = "ecs-sg"
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

resource "aws_launch_configuration" "ecs_launch_configuration" {
  name          = "ecs-launch-configuration"
  image_id      = "your_ami_id"
  instance_type = "t3.micro"  # Or any other instance type you prefer
  security_groups = [aws_security_group.ecs_sg.id]
  iam_instance_profile = "your_iam_instance_profile_id"
  user_data     = <<-EOF
                  #!/bin/bash
                  echo ECS_CLUSTER=${aws_ecs_cluster.qa_cluster.name} >> /etc/ecs/ecs.config
                  EOF
}
resource "aws_autoscaling_group" "ecs_autoscaling_group" {
  launch_configuration = aws_launch_configuration.ecs_launch_configuration.name
  min_size             = 1
  max_size             = 10
  desired_capacity     = 1
  vpc_zone_identifier  = ["your_subnet_id"]
  target_group_arns    = ["${aws_lb_target_group.auth_tg.arn}","${aws_lb_target_group.payment_tg.arn}"]

  tag {
    key                 = "Name"
    value               = "ecs-cluster-asg"
    propagate_at_launch = true
  }
}


# Log Group
resource "aws_cloudwatch_log_group" "ecs_logs" {
    name              = "aws/ecs/qa-cluster"
    retention_in_days = 30

    tags = {
        Environment = "QA"
        Project     = "ECS server"
    }
}

# resource "aws_security_group" "example_security_group_ecs" {
#   name        = "example-security-group-ecs"   # update this.
#   description = "Example security group for ECS cluster"  # update this

#   vpc_id      = aws_vpc.non_prod_vpc.id  # Replace with the ID of your VPC

#   // Define inbound and outbound rules as needed
#   // Example inbound rule allowing HTTP traffic from anywhere
#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   // Example outbound rule allowing all traffic to anywhere
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }
