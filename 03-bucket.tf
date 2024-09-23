resource "aws_s3_bucket" "web_content" {
  bucket = "${local.environment}-${local.account_id}-${local.prefix_name}-web-content"

  tags = merge(local.common_tags, {
    Name = "${local.environment}-${local.account_id}-${local.prefix_name}-web-content"
  })
}
