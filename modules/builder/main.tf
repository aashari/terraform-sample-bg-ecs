resource "aws_ecr_repository" "repository" {
  count = var.include_ecr ? 1 : 0

  name                 = "${var.prefix_name}-${var.project_name}"
  image_tag_mutability = "MUTABLE"

  tags = merge(var.common_tags, {
    Name = "${var.prefix_name}-${var.project_name}-repo"
  })
}

resource "aws_ecr_lifecycle_policy" "repository_policy" {
  count      = var.include_ecr ? 1 : 0
  repository = aws_ecr_repository.repository[0].name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = {
        type = "expire"
      }
    }]
  })
}

resource "aws_cloudwatch_log_group" "build_log_group" {
  name              = "/aws/codebuild/${var.prefix_name}-build-${var.project_name}"
  retention_in_days = var.log_retention_days

  tags = var.common_tags
}

resource "aws_codebuild_source_credential" "build_project" {
  count       = var.codestar_connection_arn != "" ? 1 : 0
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = var.codestar_connection_arn
}

resource "aws_codebuild_project" "build_project" {
  name           = "${var.prefix_name}-build-${var.project_name}"
  description    = "Build project for ${var.project_name}"
  service_role   = aws_iam_role.codebuild_service_role.arn
  source_version = var.git_branch

  source {
    type                = "GITHUB"
    location            = var.git_url
    git_clone_depth     = 1
    buildspec           = var.buildspec_path
    report_build_status = true
    git_submodules_config {
      fetch_submodules = false
    }
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
    type         = "LINUX_CONTAINER"

    dynamic "environment_variable" {
      for_each = var.environment_variables
      content {
        name  = environment_variable.value.name
        value = environment_variable.value.value
      }
    }

    dynamic "environment_variable" {
      for_each = var.include_ecr ? [1] : []
      content {
        name  = "REPOSITORY_URI"
        value = aws_ecr_repository.repository[0].repository_url
      }
    }
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = aws_cloudwatch_log_group.build_log_group.name
      stream_name = "build-log"
    }
  }

  tags = var.common_tags
}

resource "aws_iam_role" "codebuild_service_role" {
  name = "${var.prefix_name}-build-${var.project_name}-codebuild-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy" "codebuild_service_role_policy" {
  name = "${var.prefix_name}-build-${var.project_name}-codebuild-service-role-policy"
  role = aws_iam_role.codebuild_service_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      var.additional_iam_statements,
      [
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Resource = [
            aws_cloudwatch_log_group.build_log_group.arn,
            "${aws_cloudwatch_log_group.build_log_group.arn}:*"
          ]
        },
        {
          Effect = "Allow"
          Action = [
            "codebuild:BatchGetBuilds",
            "codebuild:StartBuild",
            "codebuild:StopBuild"
          ]
          Resource = [
            aws_codebuild_project.build_project.arn
          ]
        },
        {
          Action = [
            "ecr:GetAuthorizationToken"
          ]
          Resource = "*"
          Effect   = "Allow"
        }
      ],
      var.include_ecr ? [
        {
          Effect = "Allow"
          Action = [
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability",
            "ecr:PutImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload"
          ]
          Resource = [aws_ecr_repository.repository[0].arn]
        },
      ] : []
    )
  })
}
