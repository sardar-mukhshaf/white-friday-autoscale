# ------------------------------------------------------------------------------
# Infracost Usage File
# Mock usage for accurate cost prediction
# ------------------------------------------------------------------------------

aws_eks_cluster.main:
  monthly_hours: 730

aws_nat_gateway.main:
  monthly_hours: 730
  monthly_data_processed_gb: 1000

aws_lb.main:
  monthly_hours: 730
  monthly_requests: 100000000

aws_rds_cluster.aurora:
  monthly_hours: 730
  storage_gb: 500
  read_requests: 10000000
  write_requests: 1000000

aws_elasticache_replication_group.redis:
  monthly_hours: 730
  cache_size_gb: 50

aws_dynamodb_table.inventory:
  monthly_write_request_units: 10000000
  monthly_read_request_units: 100000000
  storage_gb: 100

aws_ec2_instance.karpenter_nodes:
  monthly_hours: 730
  instance_type: m6i.large
  operating_system: linux
