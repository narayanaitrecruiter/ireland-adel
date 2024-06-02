
# ECS Cluster
resource "aws_ecs_cluster" "qa_cluster" {
  name = "QA-cluster"

  tags = {
    Environment = "QA"
    Project     = "ECS server"
  }
}

# Cluster launch configuration

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

#cluster autoscaling group

resource "aws_autoscaling_group" "ecs_autoscaling_group" {
  launch_configuration = aws_launch_configuration.ecs_launch_configuration.name
  min_size             = 1
  max_size             = 10
  desired_capacity     = 1
  vpc_zone_identifier  = [aws_subnet.public_subnets[0].id]
  target_group_arns    = ["${aws_lb_target_group.ecs_tg.arn}"]

  tag {
    key                 = "Name"
    value               = "ecs-cluster-asg"
    propagate_at_launch = true
  }
}


# Log Group for ECS cluster
resource "aws_cloudwatch_log_group" "ecs_logs" {
    name              = "aws/ecs/qa-cluster"
    retention_in_days = 30

    tags = {
        Environment = "QA"
        Project     = "ECS server"
    }
}

# security group for ECS cluster

resource "aws_lb_target_group" "ecs_tg" {
  name        = "ecs-tg"
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

# Security group of ECS cluster

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



#####################TASK DEFINITION AND SERVICE DEFINITION#####################



# Task Definition - auth  using the json file in auth definition

resource "aws_ecs_task_definition" "auth" {
  family                   = "auth"
  requires_compatibilities = ["EC2"]
  cpu                      = 256
  memory                   = 512
  network_mode             = "bridge"

  container_definitions = file("${path.module}/auth-task-definition/auth-task-definition.json")

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Environment = "QA"
    Project     = "ECS server"   # update the tag as per need.
  }
}

# Service - auth  using the json format 
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
    target_group_arn = aws_lb_target_group.ecs_sg.arn
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




