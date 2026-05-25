# ------------------------------------------------------------------------------
# ElastiCache Redis (Cluster Mode Enabled)
# ------------------------------------------------------------------------------
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project_name}-${var.environment}-redis"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-redis-subnet-group"
  })
}

resource "aws_security_group" "redis" {
  name_prefix = "${var.project_name}-${var.environment}-redis-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.eks_security_group_id]
    description     = "Redis from EKS"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-redis-sg"
  })
}

resource "aws_secretsmanager_secret" "redis_auth" {
  name                    = "${var.project_name}/${var.environment}/redis-auth-token"
  description             = "Redis AUTH token"
  recovery_window_in_days = 7

  tags = var.common_tags
}

resource "aws_secretsmanager_secret_version" "redis_auth" {
  secret_id     = aws_secretsmanager_secret.redis_auth.id
  secret_string = random_password.redis_auth.result
}

resource "random_password" "redis_auth" {
  length  = 32
  special = false
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.project_name}-${var.environment}-redis"
  description          = "Redis cluster for sessions and shopping cart"

  node_type            = var.redis_node_type
  port                 = 6379
  parameter_group_name = "default.redis7.cluster.on"

  num_cache_clusters         = 2
  automatic_failover_enabled = true
  multi_az_enabled           = true

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.redis_auth.result

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]

  snapshot_retention_limit = 7
  snapshot_window          = "03:00-04:00"
  maintenance_window       = "sun:04:00-sun:05:00"

  apply_immediately = var.environment != "prod"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-redis"
  })
}

# ------------------------------------------------------------------------------
# Amazon Aurora PostgreSQL
# ------------------------------------------------------------------------------
resource "aws_db_subnet_group" "aurora" {
  name       = "${var.project_name}-${var.environment}-aurora"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-aurora-subnet-group"
  })
}

resource "aws_security_group" "aurora" {
  name_prefix = "${var.project_name}-${var.environment}-aurora-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_security_group_id]
    description     = "PostgreSQL from EKS"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-aurora-sg"
  })
}

resource "aws_secretsmanager_secret" "aurora_master" {
  name                    = "${var.project_name}/${var.environment}/aurora-master-password"
  description             = "Aurora PostgreSQL master password"
  recovery_window_in_days = 7

  tags = var.common_tags
}

resource "aws_secretsmanager_secret_version" "aurora_master" {
  secret_id     = aws_secretsmanager_secret.aurora_master.id
  secret_string = random_password.aurora_master.result
}

resource "random_password" "aurora_master" {
  length  = 32
  special = false
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier = "${var.project_name}-${var.environment}-aurora"
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned"
  engine_version     = "15.4"

  database_name   = "whitefriday"
  master_username = "admin"
  master_password = random_password.aurora_master.result

  db_subnet_group_name   = aws_db_subnet_group.aurora.name
  vpc_security_group_ids = [aws_security_group.aurora.id]

  storage_encrypted = true

  backup_retention_period = 35
  preferred_backup_window = "02:00-03:00"

  enabled_cloudwatch_logs_exports = ["postgresql"]

  deletion_protection = var.environment == "prod" ? true : false
  skip_final_snapshot = var.environment != "prod"

  serverlessv2_scaling_configuration {
    min_capacity = var.db_min_capacity
    max_capacity = var.db_max_capacity
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-aurora"
  })
}

resource "aws_rds_cluster_instance" "aurora_writer" {
  identifier           = "${var.project_name}-${var.environment}-aurora-writer"
  cluster_identifier   = aws_rds_cluster.aurora.id
  instance_class       = var.aurora_instance_class
  engine               = aws_rds_cluster.aurora.engine

  performance_insights_enabled = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-aurora-writer"
  })
}

resource "aws_rds_cluster_instance" "aurora_reader" {
  count              = var.environment == "prod" ? 2 : 1
  identifier         = "${var.project_name}-${var.environment}-aurora-reader-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = var.aurora_instance_class
  engine             = aws_rds_cluster.aurora.engine

  performance_insights_enabled = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-aurora-reader-${count.index + 1}"
  })
}

# ------------------------------------------------------------------------------
# DynamoDB for Product Inventory
# ------------------------------------------------------------------------------
resource "aws_dynamodb_table" "inventory" {
  name         = "${var.project_name}-${var.environment}-inventory"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "productId"
  range_key    = "warehouseId"

  attribute {
    name = "productId"
    type = "S"
  }

  attribute {
    name = "warehouseId"
    type = "S"
  }

  point_in_time_recovery {
    enabled = var.environment == "prod"
  }

  server_side_encryption {
    enabled = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-inventory"
  })
}
