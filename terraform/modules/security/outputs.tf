# ------------------------------------------------------------------------------
# Security Module Outputs
# ------------------------------------------------------------------------------

output "kms_key_id" {
  description = "ID of the KMS CMK"
  value       = aws_kms_key.main.id
}

output "kms_key_arn" {
  description = "ARN of the KMS CMK"
  value       = aws_kms_key.main.arn
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF WebACL"
  value       = aws_wafv2_web_acl.main.arn
}

output "waf_web_acl_id" {
  description = "ID of the WAF WebACL"
  value       = aws_wafv2_web_acl.main.id
}

output "eks_node_security_group_id" {
  description = "Security group ID for EKS nodes"
  value       = aws_security_group.eks_nodes.id
}

output "rds_security_group_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.rds.id
}

output "redis_security_group_id" {
  description = "Security group ID for Redis"
  value       = aws_security_group.redis.id
}
