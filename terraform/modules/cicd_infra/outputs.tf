# ------------------------------------------------------------------------------
# CI/CD Infrastructure Module Outputs
# ------------------------------------------------------------------------------

output "ecr_repository_urls" {
  description = "Map of microservice names to ECR repository URLs"
  value       = { for name, repo in aws_ecr_repository.microservices : name => repo.repository_url }
}

output "gitlab_runner_role_arn" {
  description = "ARN of the GitLab Runner IAM role"
  value       = aws_iam_role.gitlab_runner.arn
}
