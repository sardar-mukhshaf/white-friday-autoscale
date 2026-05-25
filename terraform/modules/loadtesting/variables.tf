# ------------------------------------------------------------------------------
# Load Testing Module Variables
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

variable "k6_vus" {
  description = "Number of virtual users for k6"
  type        = number
}

variable "k6_duration" {
  description = "Duration of k6 tests"
  type        = string
}

variable "locust_workers" {
  description = "Number of Locust worker pods"
  type        = number
}

variable "test_namespace" {
  description = "Namespace for load testing"
  type        = string
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
}
