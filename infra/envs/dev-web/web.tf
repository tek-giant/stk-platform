locals {
  image    = "${data.aws_ecr_repository.web.repository_url}:${var.image_tag}"
  registry = split("/", data.aws_ecr_repository.web.repository_url)[0]

  # Temporary: Ansible replaces this start-up script in the next task
  user_data = <<-SCRIPT
    #!/bin/bash
    set -euxo pipefail
    dnf install -y docker
    systemctl enable --now docker
    aws ecr get-login-password --region eu-west-2 | docker login --username AWS --password-stdin ${local.registry}
    docker run -d --name web --restart unless-stopped -p 8080:8080 -e API_UPSTREAM=http://${local.api_dns} ${local.image}
  SCRIPT
}

resource "aws_launch_template" "web" {
  name_prefix   = "${local.name}-web-"
  image_id      = data.aws_ssm_parameter.al2023.value
  instance_type = var.instance_type
  user_data     = base64encode(local.user_data)

  update_default_version = true

  iam_instance_profile {
    name = aws_iam_instance_profile.web.name
  }

  vpc_security_group_ids = [aws_security_group.web.id]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 8
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${local.name}-web" }
  }
}

resource "aws_lb" "public" {
  name                       = "${local.name}-public-alb"
  internal                   = false
  load_balancer_type         = "application"
  subnets                    = local.public_subnet_ids
  security_groups            = [aws_security_group.alb.id]
  drop_invalid_header_fields = true
}

resource "aws_lb_target_group" "web" {
  name        = "${local.name}-web"
  port        = 8080
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = local.vpc_id

  deregistration_delay = 30

  health_check {
    path                = "/healthz"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.public.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_autoscaling_group" "web" {
  name                      = "${local.name}-web"
  min_size                  = var.desired_count
  max_size                  = var.desired_count
  desired_capacity          = var.desired_count
  vpc_zone_identifier       = local.web_subnet_ids
  target_group_arns         = [aws_lb_target_group.web.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.web.id
    version = aws_launch_template.web.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${local.name}-web"
    propagate_at_launch = true
  }

  depends_on = [aws_lb_listener.http]
}
