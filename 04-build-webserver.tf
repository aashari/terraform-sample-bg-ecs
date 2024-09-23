module "build_webserver" {
  source = "./modules/builder"

  prefix_name             = local.prefix_name
  project_name            = "webserver"
  git_url                 = local.git_url
  buildspec_path          = "services/webserver/buildspec.yml"
  include_ecr             = true
  codestar_connection_arn = aws_codestarconnections_connection.github.arn

  environment_variables = []

  additional_iam_statements = []

  common_tags = local.common_tags
}
