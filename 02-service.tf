resource "aws_ecs_cluster" "main" {
  name = "${local.prefix_name}-ecs-cluster"

  tags = merge(local.common_tags, {
    Name = "${local.prefix_name}-ecs-cluster"
  })
}
