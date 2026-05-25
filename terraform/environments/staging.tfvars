# ------------------------------------------------------------------------------
# Staging Environment Overrides
# ------------------------------------------------------------------------------

environment = "staging"
region      = "eu-west-1"

vpc_cidr = "10.1.0.0/16"
az_count = 3

cluster_version   = "1.29"
karpenter_version = "0.34.0"

nodepool_limits_cpu    = 500
nodepool_limits_memory = 2000
enable_spot            = true
graviton3_percentage   = 40

hpa_min_replicas       = 2
hpa_max_replicas       = 50
target_rps_per_pod     = 1000
overprovision_replicas = 5

waf_rate_limit         = 3000
enable_shield_advanced = false

k6_vus         = 20000
k6_duration    = "10m"
locust_workers = 5
test_namespace = "loadtesting"

enable_chaos        = true
chaos_namespace     = "litmus"
experiments_list    = ["pod-delete", "network-latency", "zone-down", "pod-cpu-hog"]
abort_on_error_rate = 0.05

enable_jaeger      = true
retention_days     = 14
monthly_budget_usd = 15000

mandatory_tags = {
  Environment = "staging"
  Team        = "platform"
  CostCenter  = "platform-engineering"
  Project     = "whitefriday"
  Owner       = "sre-team@example.com"
}

enable_graviton3_builds = true
ecr_retention_count     = 20

redis_node_type       = "cache.r6g.large"
aurora_instance_class = "db.r6g.large"
db_min_capacity       = 2
db_max_capacity       = 32

enable_global_accelerator = false
