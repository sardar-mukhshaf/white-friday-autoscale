# ------------------------------------------------------------------------------
# Chaos Engineering Module Variables
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

variable "enable_chaos" {
  description = "Enable chaos engineering"
  type        = bool
}

variable "chaos_namespace" {
  description = "Namespace for chaos experiments"
  type        = string
}

variable "experiments_list" {
  description = "List of chaos experiments to enable"
  type        = list(string)
}

variable "abort_on_error_rate" {
  description = "Error rate threshold to auto-abort experiments"
  type        = number
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}
