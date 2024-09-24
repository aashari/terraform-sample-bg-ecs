module "build_content" {
  source = "./modules/builder"

  prefix_name             = local.prefix_name
  project_name            = "content"
  git_url                 = local.git_url
  buildspec_path          = "services/webcontent/buildspec.yml"
  include_ecr             = false
  codestar_connection_arn = aws_codestarconnections_connection.github.arn
  log_retention_days      = local.default_log_retention_days

  environment_variables = [
    {
      name  = "S3_BUCKET_NAME"
      value = aws_s3_bucket.web_content.bucket
    }
  ]

  additional_iam_statements = [
    {
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.web_content.arn,
        "${aws_s3_bucket.web_content.arn}/*",
        aws_s3_bucket.artifact_store.arn,
        "${aws_s3_bucket.artifact_store.arn}/*"
      ]
    }
  ]

  common_tags = local.common_tags
}

module "prepare_deployment" {
  source = "./modules/builder"

  prefix_name             = local.prefix_name
  project_name            = "prepare-deployment"
  git_url                 = local.git_url
  buildspec_path          = "services/deployment/buildspec.yml"
  include_ecr             = false
  codestar_connection_arn = aws_codestarconnections_connection.github.arn
  log_retention_days      = local.default_log_retention_days

  environment_variables = [
    {
      name  = "ECS_CLUSTER_NAME"
      value = aws_ecs_cluster.main.name
    },
    {
      name  = "ECS_SERVICE_NAME"
      value = aws_ecs_service.web_server.name
    },
    {
      name  = "TASK_DEFINITION_FAMILY"
      value = aws_ecs_task_definition.web_server.family
    },
    {
      name  = "WEBSERVER_IMAGE"
      value = "${module.build_webserver.ecr_repository_url}:latest"
    },
    {
      name  = "DOWNLOADER_IMAGE"
      value = "${module.build_downloader.ecr_repository_url}:latest"
    }
  ]

  additional_iam_statements = [
    {
      Effect = "Allow"
      Action = [
        "ecs:DescribeTaskDefinition",
        "ecs:DescribeServices",
        "ecs:DescribeCluster",
        "ecs:ListTaskDefinitions",
        "ecs:RegisterTaskDefinition",
        "iam:PassRole",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ]
      Resource = ["*"]
    },
    {
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:GetObjectVersion"
      ]
      Resource = [
        "${aws_s3_bucket.artifact_store.arn}/*"
      ]
    }
  ]

  common_tags = local.common_tags
}

module "build_downloader" {
  source = "./modules/builder"

  prefix_name             = local.prefix_name
  project_name            = "downloader"
  git_url                 = local.git_url
  buildspec_path          = "services/downloader/buildspec.yml"
  include_ecr             = true
  codestar_connection_arn = aws_codestarconnections_connection.github.arn
  log_retention_days      = local.default_log_retention_days

  environment_variables = [
    {
      name  = "S3_BUCKET_NAME"
      value = aws_s3_bucket.web_content.bucket
    }
  ]

  additional_iam_statements = [
    {
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.web_content.arn,
        "${aws_s3_bucket.web_content.arn}/*",
        aws_s3_bucket.artifact_store.arn,
        "${aws_s3_bucket.artifact_store.arn}/*"
      ]
    }
  ]

  common_tags = local.common_tags
}

module "build_webserver" {
  source = "./modules/builder"

  prefix_name             = local.prefix_name
  project_name            = "webserver"
  git_url                 = local.git_url
  buildspec_path          = "services/webserver/buildspec.yml"
  include_ecr             = true
  codestar_connection_arn = aws_codestarconnections_connection.github.arn
  log_retention_days      = local.default_log_retention_days

  environment_variables = []

  additional_iam_statements = [
    {
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.artifact_store.arn,
        "${aws_s3_bucket.artifact_store.arn}/*"
      ]
    }
  ]

  common_tags = local.common_tags
}
