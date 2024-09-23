variable "prefix_name" {
  description = "Prefix to be used for resource naming"
  type        = string
}

variable "project_name" {
  description = "Name of the build project (e.g., 'downloader', 'webserver', 'content')"
  type        = string
}

variable "buildspec_path" {
  description = "Path to the buildspec file within the repository"
  type        = string
}

variable "git_url" {
  description = "URL of the Git repository"
  type        = string
}

variable "git_branch" {
  description = "Branch of the Git repository"
  type        = string
  default     = "main"
}

variable "codestar_connection_arn" {
  description = "ARN of the CodeStar connection"
  type        = string
  default     = ""
}

variable "include_ecr" {
  description = "Whether to include ECR repository creation"
  type        = bool
  default     = false
}

variable "environment_variables" {
  description = "List of environment variables for the build project"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "additional_iam_statements" {
  description = "Additional IAM policy statements for the CodeBuild service role"
  type = list(object({
    Effect   = string
    Action   = list(string)
    Resource = list(string)
  }))
  default = []
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket (if needed)"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7
}
