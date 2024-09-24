resource "aws_ecs_cluster" "main" {
  name = "${local.prefix_name}-ecs-cluster"

  tags = merge(local.common_tags, {
    Name = "${local.prefix_name}-ecs-cluster"
  })
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${local.prefix_name}-web-server"
  retention_in_days = local.default_log_retention_days

  tags = merge(local.common_tags, {
    Name = "${local.prefix_name}-ecs-logs"
  })
}

resource "aws_ecs_task_definition" "web_server" {
  family                   = "${local.prefix_name}-web-server"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_service_role.arn

  volume {
    name = "web_content"
  }

  container_definitions = jsonencode([
    {
      name      = "downloader"
      image     = "${module.build_downloader.ecr_repository_url}:latest"
      essential = false
      secrets = [
        {
          name      = "FILE_TO_SERVE"
          valueFrom = aws_ssm_parameter.file_to_serve.arn
        }
      ]
      environment = [
        {
          name  = "S3_BUCKET"
          value = aws_s3_bucket.web_content.bucket
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "web_content"
          containerPath = "/data"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "downloader"
        }
      }
    },
    {
      name      = "webserver"
      image     = "${module.build_webserver.ecr_repository_url}:latest"
      essential = true
      dependsOn = [
        {
          containerName = "downloader"
          condition     = "COMPLETE"
        }
      ]
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "web_content"
          containerPath = "/data"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "webserver"
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = merge(local.common_tags, {
    Name = "${local.prefix_name}-web-server-task"
  })
}

resource "aws_ecs_service" "web_server" {
  name            = "${local.prefix_name}-web-server-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.web_server.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web_server.arn
    container_name   = "webserver"
    container_port   = 80
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  // Add this block to ensure the service depends on the listener
  depends_on = [aws_lb_listener.web_server]

  tags = merge(local.common_tags, {
    Name = "${local.prefix_name}-web-server-service"
  })

  lifecycle {
    ignore_changes = [task_definition, load_balancer]
  }
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${local.prefix_name}-ecs-tasks-sg"
  description = "Allow inbound access from the ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.alb.id]
    description     = "Allow inbound traffic from ALB"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(local.common_tags, {
    Name = "${local.prefix_name}-ecs-tasks-sg"
  })
}
