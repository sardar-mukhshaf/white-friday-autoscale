# ------------------------------------------------------------------------------
# Development Environment Overrides
# ------------------------------------------------------------------------------

environment = "dev"
region      = "eu-west-1"

vpc_cidr = "10.0.0.0/16"
az_count = 3

cluster_version   = "1.29"
karpenter_version = "0.34.0"

nodepool_limits_cpu    = 100
nodepool_limits_memory = 400
enable_spot            = true
graviton3_percentage   = 50

hpa_min_replicas       = 1
hpa_max_replicas       = 10
target_rps_per_pod     = 1000
overprovision_replicas = 2

waf_rate_limit         = 5000
enable_shield_advanced = false

k6_vus         = 1000
k6_duration    = "5m"
locust_workers = 2
test_namespace = "loadtesting"

enable_chaos        = true
chaos_namespace     = "litmus"
experiments_list    = ["pod-delete", "pod-cpu-hog"]
abort_on_error_rate = 0.05

enable_jaeger      = true
retention_days     = 7
monthly_budget_usd = 5000

mandatory_tags = {
  Environment = "dev"
  Team        = "platform"
  CostCenter  = "platform-engineering"
  Project     = "whitefriday"
  Owner       = "sre-team@example.com"
}

enable_graviton3_builds = true
ecr_retention_count     = 10

redis_node_type       = "cache.t4g.medium"
aurora_instance_class = "db.t4g.medium"
db_min_capacity       = 0.5
db_max_capacity       = 8

enable_global_accelerator = false
