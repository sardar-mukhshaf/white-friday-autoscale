# ------------------------------------------------------------------------------
# Local Values
# ------------------------------------------------------------------------------
locals {
  name_prefix = "${var.project_name}-${var.environment}-${var.region}"

  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  common_tags = merge(var.common_tags, {
    Environment = var.environment
    Name        = local.name_prefix
  })
}

# ------------------------------------------------------------------------------
# Networking Module
# ------------------------------------------------------------------------------
module "networking" {
  source = "./modules/networking"

  project_name              = var.project_name
  environment               = var.environment
  region                    = var.region
  vpc_cidr                  = var.vpc_cidr
  azs                       = local.azs
  az_count                  = var.az_count
  enable_global_accelerator = var.enable_global_accelerator
  private_subnet_tags       = var.private_subnet_tags
  common_tags               = local.common_tags
}

# ------------------------------------------------------------------------------
# EKS + Karpenter Module
# ------------------------------------------------------------------------------
module "eks_karpenter" {
  source = "./modules/eks_karpenter"

  project_name           = var.project_name
  environment            = var.environment
  region                 = var.region
  cluster_version        = var.cluster_version
  karpenter_version      = var.karpenter_version
  vpc_id                 = module.networking.vpc_id
  private_subnet_ids     = module.networking.private_subnet_ids
  az_count               = var.az_count
  nodepool_limits_cpu    = var.nodepool_limits_cpu
  nodepool_limits_memory = var.nodepool_limits_memory
  enable_spot            = var.enable_spot
  graviton3_percentage   = var.graviton3_percentage
  common_tags            = local.common_tags

  depends_on = [module.networking]
}

# ------------------------------------------------------------------------------
# Security Module
# ------------------------------------------------------------------------------
module "security" {
  source = "./modules/security"

  project_name           = var.project_name
  environment            = var.environment
  region                 = var.region
  vpc_id                 = module.networking.vpc_id
  alb_arn                = module.networking.alb_arn
  allowed_countries      = var.allowed_countries
  waf_rate_limit         = var.waf_rate_limit
  enable_bot_control     = var.enable_bot_control
  enable_shield_advanced = var.enable_shield_advanced
  common_tags            = local.common_tags

  depends_on = [module.networking]
}

# ------------------------------------------------------------------------------
# Database Module
# ------------------------------------------------------------------------------
module "database" {
  source = "./modules/database"

  project_name        = var.project_name
  environment         = var.environment
  region              = var.region
  vpc_id              = module.networking.vpc_id
  private_subnet_ids  = module.networking.private_subnet_ids
  eks_security_group_id = module.eks_karpenter.cluster_security_group_id
  redis_node_type     = var.redis_node_type
  aurora_instance_class = var.aurora_instance_class
  db_min_capacity     = var.db_min_capacity
  db_max_capacity     = var.db_max_capacity
  common_tags         = local.common_tags

  depends_on = [module.networking, module.eks_karpenter]
}

# ------------------------------------------------------------------------------
# Autoscaling Module
# ------------------------------------------------------------------------------
module "autoscaling" {
  source = "./modules/autoscaling"

  project_name           = var.project_name
  environment            = var.environment
  hpa_min_replicas       = var.hpa_min_replicas
  hpa_max_replicas       = var.hpa_max_replicas
  target_rps_per_pod     = var.target_rps_per_pod
  overprovision_replicas = var.overprovision_replicas
  cluster_name           = module.eks_karpenter.cluster_name
  oidc_provider_arn      = module.eks_karpenter.oidc_provider_arn
  common_tags            = local.common_tags

  depends_on = [module.eks_karpenter]
}

# ------------------------------------------------------------------------------
# CI/CD Infrastructure Module
# ------------------------------------------------------------------------------
module "cicd_infra" {
  source = "./modules/cicd_infra"

  project_name            = var.project_name
  environment             = var.environment
  region                  = var.region
  vpc_id                  = module.networking.vpc_id
  private_subnet_ids      = module.networking.private_subnet_ids
  cluster_name            = module.eks_karpenter.cluster_name
  cluster_oidc_issuer_url = module.eks_karpenter.cluster_oidc_issuer_url
  gitlab_url              = var.gitlab_url
  runner_token_secret_arn = var.runner_token_secret_arn
  enable_graviton3_builds = var.enable_graviton3_builds
  ecr_retention_count     = var.ecr_retention_count
  common_tags             = local.common_tags

  depends_on = [module.eks_karpenter, module.networking]
}

# ------------------------------------------------------------------------------
# Observability Module
# ------------------------------------------------------------------------------
module "observability" {
  source = "./modules/observability"

  project_name                = var.project_name
  environment                 = var.environment
  region                      = var.region
  cluster_name                = module.eks_karpenter.cluster_name
  grafana_admin_password_secret = var.grafana_admin_password_secret
  enable_jaeger               = var.enable_jaeger
  retention_days              = var.retention_days
  pagerduty_service_key       = var.pagerduty_service_key
  common_tags                 = local.common_tags

  depends_on = [module.eks_karpenter]
}

# ------------------------------------------------------------------------------
# Load Testing Module
# ------------------------------------------------------------------------------
module "loadtesting" {
  source = "./modules/loadtesting"

  project_name      = var.project_name
  environment       = var.environment
  region            = var.region
  cluster_name      = module.eks_karpenter.cluster_name
  k6_vus            = var.k6_vus
  k6_duration       = var.k6_duration
  locust_workers    = var.locust_workers
  test_namespace    = var.test_namespace
  common_tags       = local.common_tags

  depends_on = [module.eks_karpenter]
}

# ------------------------------------------------------------------------------
# Chaos Engineering Module
# ------------------------------------------------------------------------------
module "chaos" {
  source = "./modules/chaos"

  project_name        = var.project_name
  environment         = var.environment
  region              = var.region
  cluster_name        = module.eks_karpenter.cluster_name
  enable_chaos        = var.enable_chaos
  chaos_namespace     = var.chaos_namespace
  experiments_list    = var.experiments_list
  abort_on_error_rate = var.abort_on_error_rate
  common_tags         = local.common_tags

  depends_on = [module.eks_karpenter]
}

# ------------------------------------------------------------------------------
# FinOps Module
# ------------------------------------------------------------------------------
module "finops" {
  source = "./modules/finops"

  project_name        = var.project_name
  environment         = var.environment
  region              = var.region
  monthly_budget_usd  = var.monthly_budget_usd
  cost_alert_threshold = var.cost_alert_threshold
  mandatory_tags      = var.mandatory_tags
  common_tags         = local.common_tags
}
