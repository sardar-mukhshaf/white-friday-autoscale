# ------------------------------------------------------------------------------
# Autoscaling Module Variables
# ------------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "hpa_min_replicas" {
  description = "Minimum HPA replicas"
  type        = number
}

variable "hpa_max_replicas" {
  description = "Maximum HPA replicas"
  type        = number
}

variable "target_rps_per_pod" {
  description = "Target RPS per pod for custom metrics"
  type        = number
}

variable "overprovision_replicas" {
  description = "Number of pause pod replicas for over-provisioning"
  type        = number
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}
