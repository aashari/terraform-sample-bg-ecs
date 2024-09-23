output "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  value       = aws_codebuild_project.build_project.name
}

output "codebuild_project_arn" {
  description = "ARN of the CodeBuild project"
  value       = aws_codebuild_project.build_project.arn
}

output "codebuild_service_role_name" {
  description = "Name of the IAM service role for CodeBuild"
  value       = aws_iam_role.codebuild_service_role.name
}

output "codebuild_service_role_arn" {
  description = "ARN of the IAM service role for CodeBuild"
  value       = aws_iam_role.codebuild_service_role.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for the build project"
  value       = aws_cloudwatch_log_group.build_log_group.name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository (if created)"
  value       = var.include_ecr ? aws_ecr_repository.repository[0].repository_url : null
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository (if created)"
  value       = var.include_ecr ? aws_ecr_repository.repository[0].arn : null
}
