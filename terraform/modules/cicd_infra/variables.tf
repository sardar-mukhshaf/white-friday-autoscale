# ------------------------------------------------------------------------------
# CI/CD Infrastructure Module Variables
# ------------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "EKS OIDC issuer URL"
  type        = string
}

variable "gitlab_url" {
  description = "GitLab instance URL"
  type        = string
}

variable "runner_token_secret_arn" {
  description = "ARN of the GitLab runner token secret"
  type        = string
}

variable "enable_graviton3_builds" {
  description = "Enable multi-arch Graviton3 builds"
  type        = bool
}

variable "ecr_retention_count" {
  description = "Number of images to retain in ECR"
  type        = number
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}
