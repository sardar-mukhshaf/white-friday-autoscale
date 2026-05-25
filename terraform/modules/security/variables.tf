# ------------------------------------------------------------------------------
# Security Module Variables
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

variable "alb_arn" {
  description = "ARN of the Application Load Balancer"
  type        = string
}

variable "allowed_countries" {
  description = "List of allowed country codes"
  type        = list(string)
}

variable "waf_rate_limit" {
  description = "WAF rate limit per IP"
  type        = number
}

variable "enable_bot_control" {
  description = "Enable AWS WAF Bot Control"
  type        = bool
}

variable "enable_shield_advanced" {
  description = "Enable AWS Shield Advanced"
  type        = bool
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}
