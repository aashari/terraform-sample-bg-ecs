module "build_downloader" {
  source = "./modules/builder"

  prefix_name             = local.prefix_name
  project_name            = "downloader"
  git_url                 = local.git_url
  buildspec_path          = "services/downloader/buildspec.yml"
  include_ecr             = true
  codestar_connection_arn = aws_codestarconnections_connection.github.arn

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
        "${aws_s3_bucket.web_content.arn}/*"
      ]
    }
  ]

  common_tags = local.common_tags
}
