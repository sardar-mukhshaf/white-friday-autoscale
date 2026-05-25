# ------------------------------------------------------------------------------
# Production Environment Overrides
# ------------------------------------------------------------------------------

environment = "prod"
region      = "eu-west-1"

vpc_cidr = "10.2.0.0/16"
az_count = 3

cluster_version   = "1.29"
karpenter_version = "0.34.0"

nodepool_limits_cpu    = 1000
nodepool_limits_memory = 4000
enable_spot            = true
graviton3_percentage   = 40

hpa_min_replicas       = 3
hpa_max_replicas       = 1000
target_rps_per_pod     = 1000
overprovision_replicas = 20

waf_rate_limit         = 2000
enable_bot_control     = true
enable_shield_advanced = true

k6_vus         = 100000
k6_duration    = "15m"
locust_workers = 20
test_namespace = "loadtesting"

enable_chaos        = false
chaos_namespace     = "litmus"
experiments_list    = []
abort_on_error_rate = 0.01

enable_jaeger      = true
retention_days     = 90
monthly_budget_usd = 100000

mandatory_tags = {
  Environment = "prod"
  Team        = "platform"
  CostCenter  = "platform-engineering"
  Project     = "whitefriday"
  Owner       = "sre-team@example.com"
}

enable_graviton3_builds = true
ecr_retention_count     = 30

redis_node_type       = "cache.r6g.xlarge"
aurora_instance_class = "db.r6g.xlarge"
db_min_capacity       = 4
db_max_capacity       = 128

enable_global_accelerator = true
