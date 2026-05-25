# ------------------------------------------------------------------------------
# Global Terraform Variables
# ------------------------------------------------------------------------------

project_name = "whitefriday"
environment  = "dev"
region       = "eu-west-1"

common_tags = {
  Project     = "whitefriday"
  ManagedBy   = "terraform"
  CostCenter  = "platform-engineering"
  Owner       = "sre-team@example.com"
  Team        = "platform"
}

vpc_cidr = "10.0.0.0/16"
az_count = 3

cluster_version   = "1.29"
karpenter_version = "0.34.0"

nodepool_limits_cpu    = 1000
nodepool_limits_memory = 4000
enable_spot            = true
graviton3_percentage   = 40

hpa_min_replicas       = 2
hpa_max_replicas       = 100
target_rps_per_pod     = 1000
overprovision_replicas = 10

allowed_countries  = ["SA", "AE", "BH", "KW", "EG"]
waf_rate_limit     = 2000
enable_bot_control = true
enable_shield_advanced = false

k6_vus         = 50000
k6_duration    = "10m"
locust_workers = 10
test_namespace = "loadtesting"

enable_chaos        = true
chaos_namespace     = "litmus"
experiments_list    = ["pod-delete", "network-latency", "zone-down", "pod-cpu-hog"]
abort_on_error_rate = 0.05

grafana_admin_password_secret = "whitefriday/grafana-admin-password"
enable_jaeger                 = true
retention_days                = 30

monthly_budget_usd   = 50000
cost_alert_threshold = 120

mandatory_tags = {
  Environment = "dev"
  Team        = "platform"
  CostCenter  = "platform-engineering"
  Project     = "whitefriday"
  Owner       = "sre-team@example.com"
}

gitlab_url              = "https://gitlab.com"
runner_token_secret_arn = ""
enable_graviton3_builds = true
ecr_retention_count     = 30

redis_node_type       = "cache.r6g.large"
aurora_instance_class = "db.r6g.large"
db_min_capacity       = 2
db_max_capacity       = 64

enable_global_accelerator = true
private_subnet_tags       = {}
