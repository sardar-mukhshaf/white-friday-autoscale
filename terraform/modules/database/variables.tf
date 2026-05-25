# ------------------------------------------------------------------------------
# Database Module Variables
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

variable "eks_security_group_id" {
  description = "EKS cluster security group ID"
  type        = string
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
}

variable "aurora_instance_class" {
  description = "Aurora PostgreSQL instance class"
  type        = string
}

variable "db_min_capacity" {
  description = "Minimum Aurora Serverless v2 capacity"
  type        = number
}

variable "db_max_capacity" {
  description = "Maximum Aurora Serverless v2 capacity"
  type        = number
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}
