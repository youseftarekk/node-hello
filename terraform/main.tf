provider "aws" {
  region = "us-east-1"  # Free tier 
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"  # Update to latest version

  name = "node-hello-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true  
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "node-hello-cluster"
}

# Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = "node-hello-app"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = 256
  memory                  = 512

  container_definitions = jsonencode([
    {
      name      = "node-hello"
      image     = "${var.docker_image}:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]
    }
  ])
}

# ECS Service
# Application Load Balancer
resource "aws_lb" "main" {
  name               = "node-hello-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets
}

# ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# Target Group
resource "aws_lb_target_group" "app" {
  name        = "node-hello-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "2"
    interval           = "30"
    protocol           = "HTTP"
    matcher            = "200"
    timeout            = "3"
    path               = "/"
    unhealthy_threshold = "2"
  }
}

# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "node-hello-alb"
  description = "ALB Security Group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Update ECS Service to use ALB
resource "aws_ecs_service" "app" {
  name            = "node-hello-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "node-hello"
    container_port   = 3000
  }
}

# Output the ALB DNS name
output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "The DNS name of the load balancer"
}

# Security Group
resource "aws_security_group" "ecs_tasks" {
  name        = "node-hello-ecs-tasks"
  description = "Allow inbound traffic for ECS tasks"
  vpc_id      = module.vpc.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 3000
    to_port     = 3000
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}