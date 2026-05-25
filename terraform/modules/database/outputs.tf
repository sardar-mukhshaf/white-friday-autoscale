# ------------------------------------------------------------------------------
# Database Module Outputs
# ------------------------------------------------------------------------------

output "redis_endpoint" {
  description = "ElastiCache Redis primary endpoint"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
  sensitive   = true
}

output "redis_reader_endpoint" {
  description = "ElastiCache Redis reader endpoint"
  value       = aws_elasticache_replication_group.redis.reader_endpoint_address
  sensitive   = true
}

output "redis_auth_token_secret_arn" {
  description = "ARN of the Redis auth token secret"
  value       = aws_secretsmanager_secret.redis_auth.arn
}

output "aurora_cluster_endpoint" {
  description = "Aurora cluster writer endpoint"
  value       = aws_rds_cluster.aurora.endpoint
  sensitive   = true
}

output "aurora_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = aws_rds_cluster.aurora.reader_endpoint
  sensitive   = true
}

output "aurora_master_secret_arn" {
  description = "ARN of the Aurora master password secret"
  value       = aws_secretsmanager_secret.aurora_master.arn
}

output "dynamodb_inventory_table_name" {
  description = "Name of the DynamoDB inventory table"
  value       = aws_dynamodb_table.inventory.name
}

output "dynamodb_inventory_table_arn" {
  description = "ARN of the DynamoDB inventory table"
  value       = aws_dynamodb_table.inventory.arn
}
