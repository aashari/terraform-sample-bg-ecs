resource "aws_codestarconnections_connection" "github" {
  name          = "${local.prefix_name}-github-connection"
  provider_type = "GitHub"

  tags = merge(local.common_tags, {
    Name = "github"
  })
}

resource "aws_s3_bucket" "web_content" {
  bucket = "${local.environment}-${local.account_id}-${local.prefix_name}-web-content"

  tags = merge(local.common_tags, {
    Name = "${local.environment}-${local.account_id}-${local.prefix_name}-web-content"
  })
}

resource "aws_ssm_parameter" "file_to_serve" {
  name  = "/${local.prefix_name}/file_to_serve"
  type  = "String"
  value = "index-01.html"

  tags = merge(local.common_tags, {
    Name = "${local.prefix_name}-file-to-serve-parameter"
  })

  lifecycle {
    ignore_changes = [value]
  }
}
