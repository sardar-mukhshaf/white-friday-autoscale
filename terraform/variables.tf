# ------------------------------------------------------------------------------
# Global Variables
# ------------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project used for resource naming"
  type        = string
  default     = "whitefriday"
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "chaos"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, chaos."
  }
}

variable "region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "eu-west-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.region))
    error_message = "Region must be a valid AWS region format (e.g., eu-west-1)."
  }
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Project     = "whitefriday"
    ManagedBy   = "terraform"
    CostCenter  = "platform-engineering"
    Owner       = "sre-team@example.com"
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 3

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "AZ count must be 2 or 3."
  }
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "karpenter_version" {
  description = "Karpenter Helm chart version"
  type        = string
  default     = "0.34.0"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.karpenter_version))
    error_message = "Karpenter version must be in semantic versioning format (e.g., 0.34.0)."
  }
}

variable "nodepool_limits_cpu" {
  description = "Maximum CPU limit for Karpenter NodePools"
  type        = number
  default     = 1000
}

variable "nodepool_limits_memory" {
  description = "Maximum memory limit (Gi) for Karpenter NodePools"
  type        = number
  default     = 4000
}

variable "enable_spot" {
  description = "Enable spot instance NodePools"
  type        = bool
  default     = true
}

variable "graviton3_percentage" {
  description = "Target percentage of Graviton3 (ARM64) nodes"
  type        = number
  default     = 40

  validation {
    condition     = var.graviton3_percentage >= 0 && var.graviton3_percentage <= 100
    error_message = "Graviton3 percentage must be between 0 and 100."
  }
}

variable "hpa_min_replicas" {
  description = "Minimum HPA replicas for microservices"
  type        = number
  default     = 2
}

variable "hpa_max_replicas" {
  description = "Maximum HPA replicas for microservices"
  type        = number
  default     = 100
}

variable "target_rps_per_pod" {
  description = "Target requests per second per pod for HPA custom metrics"
  type        = number
  default     = 1000
}

variable "overprovision_replicas" {
  description = "Number of pause pod replicas for over-provisioning warm nodes"
  type        = number
  default     = 10
}

variable "allowed_countries" {
  description = "List of allowed country codes for WAF geo-blocking"
  type        = list(string)
  default     = ["SA", "AE", "BH", "KW", "EG"]
}

variable "waf_rate_limit" {
  description = "WAF rate limit per IP (requests per 5 minutes)"
  type        = number
  default     = 2000
}

variable "enable_bot_control" {
  description = "Enable AWS WAF Bot Control managed rule group"
  type        = bool
  default     = true
}

variable "enable_shield_advanced" {
  description = "Enable AWS Shield Advanced DDoS protection"
  type        = bool
  default     = false
}

variable "k6_vus" {
  description = "Number of virtual users for k6 load tests"
  type        = number
  default     = 50000
}

variable "k6_duration" {
  description = "Duration of k6 load tests"
  type        = string
  default     = "10m"
}

variable "locust_workers" {
  description = "Number of Locust worker pods"
  type        = number
  default     = 10
}

variable "test_namespace" {
  description = "Kubernetes namespace for load testing resources"
  type        = string
  default     = "loadtesting"
}

variable "enable_chaos" {
  description = "Enable chaos engineering experiments"
  type        = bool
  default     = true
}

variable "chaos_namespace" {
  description = "Kubernetes namespace for chaos experiments"
  type        = string
  default     = "litmus"
}

variable "experiments_list" {
  description = "List of chaos experiments to enable"
  type        = list(string)
  default     = ["pod-delete", "network-latency", "zone-down", "pod-cpu-hog"]
}

variable "abort_on_error_rate" {
  description = "Error rate threshold to auto-abort chaos experiments"
  type        = number
  default     = 0.05
}

variable "grafana_admin_password_secret" {
  description = "AWS Secrets Manager secret name for Grafana admin password"
  type        = string
  default     = "whitefriday/grafana-admin-password"
}

variable "enable_jaeger" {
  description = "Enable Jaeger distributed tracing"
  type        = bool
  default     = true
}

variable "retention_days" {
  description = "Data retention period for observability tools"
  type        = number
  default     = 30
}

variable "pagerduty_service_key" {
  description = "PagerDuty service integration key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "monthly_budget_usd" {
  description = "Monthly AWS budget in USD"
  type        = number
  default     = 50000

  validation {
    condition     = var.monthly_budget_usd > 0
    error_message = "Monthly budget must be greater than 0."
  }
}

variable "cost_alert_threshold" {
  description = "Cost anomaly alert threshold percentage"
  type        = number
  default     = 120
}

variable "mandatory_tags" {
  description = "Mandatory tags enforced via AWS Config"
  type        = map(string)
  default = {
    Environment = ""
    Team        = "platform"
    CostCenter  = "platform-engineering"
    Project     = "whitefriday"
    Owner       = "sre-team@example.com"
  }
}

variable "gitlab_url" {
  description = "GitLab instance URL"
  type        = string
  default     = "https://gitlab.com"
}

variable "runner_token_secret_arn" {
  description = "AWS Secrets Manager ARN for GitLab runner registration token"
  type        = string
  default     = ""
}

variable "enable_graviton3_builds" {
  description = "Enable multi-arch Graviton3 builds in CI/CD"
  type        = bool
  default     = true
}

variable "ecr_retention_count" {
  description = "Number of images to retain in ECR repositories"
  type        = number
  default     = 30
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.r6g.large"
}

variable "aurora_instance_class" {
  description = "Aurora PostgreSQL instance class"
  type        = string
  default     = "db.r6g.large"
}

variable "db_min_capacity" {
  description = "Minimum Aurora Serverless v2 capacity"
  type        = number
  default     = 2
}

variable "db_max_capacity" {
  description = "Maximum Aurora Serverless v2 capacity"
  type        = number
  default     = 64
}

variable "enable_global_accelerator" {
  description = "Enable AWS Global Accelerator"
  type        = bool
  default     = true
}

variable "private_subnet_tags" {
  description = "Additional tags for private subnets"
  type        = map(string)
  default     = {}
}
