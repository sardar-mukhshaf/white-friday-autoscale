# ------------------------------------------------------------------------------
# ECR Repositories (one per microservice)
# ------------------------------------------------------------------------------
locals {
  microservices = ["frontend", "product-service", "cart-service", "order-service", "payment-service"]
}

resource "aws_ecr_repository" "microservices" {
  for_each = toset(local.microservices)

  name                 = "${var.project_name}/${each.value}"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = var.environment != "prod"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}/${each.value}"
  })

  lifecycle {
    prevent_destroy = var.environment == "prod"
  }
}

resource "aws_ecr_lifecycle_policy" "microservices" {
  for_each = aws_ecr_repository.microservices

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.ecr_retention_count} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.ecr_retention_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ------------------------------------------------------------------------------
# ECR Cross-Region Replication
# ------------------------------------------------------------------------------
resource "aws_ecr_replication_configuration" "main" {
  count = var.environment == "prod" ? 1 : 0

  replication_configuration {
    rule {
      destination {
        region      = "eu-central-1"
        registry_id = data.aws_caller_identity.current.account_id
      }
    }
  }
}

data "aws_caller_identity" "current" {}

# ------------------------------------------------------------------------------
# GitLab Runner on EKS
# ------------------------------------------------------------------------------
resource "helm_release" "gitlab_runner" {
  namespace        = "gitlab-runner"
  create_namespace = true

  name       = "gitlab-runner"
  repository = "https://charts.gitlab.io"
  chart      = "gitlab-runner"
  version    = "0.59.1"

  set {
    name  = "gitlabUrl"
    value = var.gitlab_url
  }

  set {
    name  = "runnerToken"
    value = data.aws_secretsmanager_secret_version.runner_token.secret_string
  }

  set {
    name  = "rbac.create"
    value = "true"
  }

  set {
    name  = "rbac.serviceAccountAnnotations.eks\.amazonaws\.com/role-arn"
    value = aws_iam_role.gitlab_runner.arn
  }

  set {
    name  = "runners.config"
    value = <<EOF
[[runners]]
  executor = "kubernetes"
  [runners.kubernetes]
    image = "ubuntu:22.04"
    privileged = true
    [runners.kubernetes.node_selector]
      workload-type = "ci"
EOF
  }

  set {
    name  = "runners.tags"
    value = "eks,${var.environment}"
  }
}

data "aws_secretsmanager_secret_version" "runner_token" {
  secret_id = var.runner_token_secret_arn != "" ? var.runner_token_secret_arn : "dummy"
}

# ------------------------------------------------------------------------------
# GitLab Runner IRSA
# ------------------------------------------------------------------------------
resource "aws_iam_role" "gitlab_runner" {
  name = "${var.project_name}-${var.environment}-gitlab-runner"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.cluster_oidc_issuer_url
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(var.cluster_oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
          "${replace(var.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:gitlab-runner:gitlab-runner"
        }
      }
    }]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-gitlab-runner"
  })
}

resource "aws_iam_policy" "gitlab_runner" {
  name        = "${var.project_name}-${var.environment}-gitlab-runner"
  description = "GitLab Runner policy for ECR, EKS, S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAccess"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*"
      },
      {
        Sid    = "EKSAccess"
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-artifacts-*",
          "arn:aws:s3:::${var.project_name}-artifacts-*/*"
        ]
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "gitlab_runner" {
  policy_arn = aws_iam_policy.gitlab_runner.arn
  role       = aws_iam_role.gitlab_runner.name
}
