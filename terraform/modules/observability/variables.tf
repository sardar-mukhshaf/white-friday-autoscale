# ------------------------------------------------------------------------------
# Observability Module Variables
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

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "grafana_admin_password_secret" {
  description = "AWS Secrets Manager secret name for Grafana admin password"
  type        = string
}

variable "enable_jaeger" {
  description = "Enable Jaeger tracing"
  type        = bool
}

variable "retention_days" {
  description = "Data retention period"
  type        = number
}

variable "pagerduty_service_key" {
  description = "PagerDuty service integration key"
  type        = string
  sensitive   = true
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}
