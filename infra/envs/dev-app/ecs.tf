resource "aws_ecs_cluster" "main" {
  name = "${local.name}-cluster"
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${local.name}/stock-api"
  retention_in_days = 14
}

resource "aws_ecs_task_definition" "stock_api" {
  family                   = "${local.name}-stock-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([{
    name      = "stock-api"
    image     = "${local.ecr_repository_url}:${var.image_tag}"
    essential = true

    portMappings = [{
      containerPort = 8080
      protocol      = "tcp"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.app.name
        "awslogs-region"        = "eu-west-2"
        "awslogs-stream-prefix" = "stock-api"
      }
    }
  }])
}

resource "aws_lb" "internal" {
  name                       = "${local.name}-alb"
  internal                   = true
  load_balancer_type         = "application"
  subnets                    = local.app_subnet_ids
  security_groups            = [aws_security_group.alb.id]
  drop_invalid_header_fields = true
}

resource "aws_lb_target_group" "app" {
  name        = "${local.name}-app"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  deregistration_delay = 30

  health_check {
    path                = "/actuator/health"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_ecs_service" "stock_api" {
  name            = "stock-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.stock_api.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  health_check_grace_period_seconds  = 90
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = local.app_subnet_ids
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "stock-api"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.http]
}
