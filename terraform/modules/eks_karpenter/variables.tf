# ------------------------------------------------------------------------------
# EKS + Karpenter Module Variables
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

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
}

variable "karpenter_version" {
  description = "Karpenter Helm chart version"
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

variable "nodepool_limits_cpu" {
  description = "Maximum CPU limit for Karpenter NodePools"
  type        = number
}

variable "nodepool_limits_memory" {
  description = "Maximum memory limit (Gi) for Karpenter NodePools"
  type        = number
}

variable "enable_spot" {
  description = "Enable spot instance NodePools"
  type        = bool
}

variable "graviton3_percentage" {
  description = "Target percentage of Graviton3 nodes"
  type        = number
}

variable "az_count" {
  description = "Number of availability zones"
  type        = number
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}
