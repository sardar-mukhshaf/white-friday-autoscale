# ------------------------------------------------------------------------------
# FinOps Module Variables
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

variable "monthly_budget_usd" {
  description = "Monthly AWS budget in USD"
  type        = number
}

variable "cost_alert_threshold" {
  description = "Cost anomaly alert threshold percentage"
  type        = number
}

variable "mandatory_tags" {
  description = "Mandatory tags enforced via AWS Config"
  type        = map(string)
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}
