resource "aws_codepipeline" "web_server_pipeline" {
  name     = "${local.prefix_name}-web-server-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifact_store.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn        = aws_codestarconnections_connection.github.arn
        FullRepositoryId     = "aashari/terraform-sample-ecsbg"
        BranchName           = local.git_branch
        DetectChanges        = true
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Prepare_Deployment"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["deployment_artifacts"]
      version          = "1"

      configuration = {
        ProjectName = module.prepare_deployment.codebuild_project_name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      input_artifacts = ["deployment_artifacts"]
      version         = "1"

      configuration = {
        ApplicationName                = aws_codedeploy_app.web_server.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.web_server.deployment_group_name
        TaskDefinitionTemplateArtifact = "deployment_artifacts"
        TaskDefinitionTemplatePath     = "taskdef.json"
        AppSpecTemplateArtifact        = "deployment_artifacts"
        AppSpecTemplatePath            = "appspec.yaml"
      }
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.prefix_name}-web-server-pipeline"
  })
}

resource "aws_s3_bucket" "artifact_store" {
  bucket = "${local.prefix_name}-artifact-store"

  tags = merge(local.common_tags, {
    Name = "${local.prefix_name}-artifact-store"
  })
}

resource "aws_iam_role" "codepipeline_role" {
  name = "${local.prefix_name}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.prefix_name}-codepipeline-role"
  })
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${local.prefix_name}-codepipeline-policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.artifact_store.arn,
          "${aws_s3_bucket.artifact_store.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = aws_codestarconnections_connection.github.arn
      },
      // Add this new statement for ECS permissions
      {
        Effect = "Allow"
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeServices",
          "ecs:UpdateService"
        ]
        Resource = "*"
      },
      // Update the existing IAM PassRole statement
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = [
          aws_iam_role.ecs_service_role.arn,
          aws_iam_role.ecs_task_execution_role.arn
        ]
      }
    ]
  })
}

resource "aws_codestarconnections_connection" "github" {
  name          = "${local.prefix_name}-github-connection"
  provider_type = "GitHub"

  tags = merge(local.common_tags, {
    Name = "github"
  })
}

resource "aws_codedeploy_app" "web_server" {
  compute_platform = "ECS"
  name             = "${local.prefix_name}-web-server-app"

  tags = merge(local.common_tags, {
    Name = "${local.prefix_name}-web-server-app"
  })
}

resource "aws_codedeploy_deployment_group" "web_server" {
  app_name               = aws_codedeploy_app.web_server.name
  deployment_group_name  = "${local.prefix_name}-web-server-dg"
  service_role_arn       = aws_iam_role.codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  ecs_service {
    cluster_name = aws_ecs_cluster.main.name
    service_name = aws_ecs_service.web_server.name
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  // Add this load_balancer_info block
  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.web_server.arn]
      }

      target_group {
        name = aws_lb_target_group.web_server.name
      }

      target_group {
        name = aws_lb_target_group.web_server_blue.name
      }
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.prefix_name}-web-server-dg"
  })
}

resource "aws_iam_role" "codedeploy_role" {
  name = "${local.prefix_name}-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${local.prefix_name}-codedeploy-role"
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
  role       = aws_iam_role.codedeploy_role.name
}

// Add this new target group for blue/green deployment
resource "aws_lb_target_group" "web_server_blue" {
  name        = "${local.prefix_name}-tg-blue"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "5"
    path                = "/"
    unhealthy_threshold = "2"
  }

  tags = merge(local.common_tags, {
    Name = "${local.prefix_name}-tg-blue"
  })
}
