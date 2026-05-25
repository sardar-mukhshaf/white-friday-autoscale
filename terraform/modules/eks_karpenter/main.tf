# ------------------------------------------------------------------------------
# KMS Key for EKS Secrets Encryption
# ------------------------------------------------------------------------------
resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-eks-kms"
  })
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.project_name}-${var.environment}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

# ------------------------------------------------------------------------------
# EKS Cluster
# ------------------------------------------------------------------------------
resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-${var.environment}"
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
    security_group_ids      = [aws_security_group.cluster.id]
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policies,
    aws_cloudwatch_log_group.eks,
  ]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}"
  })
}

resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.project_name}-${var.environment}/cluster"
  retention_in_days = 30

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-eks-logs"
  })
}

# ------------------------------------------------------------------------------
# EKS Cluster IAM Role
# ------------------------------------------------------------------------------
resource "aws_iam_role" "cluster" {
  name = "${var.project_name}-${var.environment}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-eks-cluster-role"
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController",
  ])

  policy_arn = each.value
  role       = aws_iam_role.cluster.name
}

# ------------------------------------------------------------------------------
# EKS Cluster Security Group
# ------------------------------------------------------------------------------
resource "aws_security_group" "cluster" {
  name_prefix = "${var.project_name}-${var.environment}-eks-cluster-"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(var.common_tags, {
    Name                                        = "${var.project_name}-${var.environment}-eks-cluster-sg"
    "kubernetes.io/cluster/${var.project_name}-${var.environment}" = "owned"
  })
}

# ------------------------------------------------------------------------------
# OIDC Provider
# ------------------------------------------------------------------------------
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-eks-oidc"
  })
}

# ------------------------------------------------------------------------------
# Karpenter IAM Role (IRSA)
# ------------------------------------------------------------------------------
resource "aws_iam_role" "karpenter_controller" {
  name = "${var.project_name}-${var.environment}-karpenter-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:karpenter:karpenter"
        }
      }
    }]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-karpenter-controller"
  })
}

resource "aws_iam_policy" "karpenter_controller" {
  name        = "${var.project_name}-${var.environment}-karpenter-controller"
  description = "Karpenter controller policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Karpenter"
        Effect = "Allow"
        Action = [
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:RunInstances",
          "ec2:CreateTags",
          "iam:PassRole",
          "ec2:TerminateInstances",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ssm:GetParameter",
          "pricing:GetProducts",
          "ec2:DescribeSpotPriceHistory"
        ]
        Resource = "*"
      },
      {
        Sid    = "ConditionalEC2Termination"
        Effect = "Allow"
        Action = "ec2:TerminateInstances"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/Name" = "*karpenter*"
          }
        }
        Resource = "*"
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "karpenter_controller" {
  policy_arn = aws_iam_policy.karpenter_controller.arn
  role       = aws_iam_role.karpenter_controller.name
}

# ------------------------------------------------------------------------------
# Karpenter Node IAM Role
# ------------------------------------------------------------------------------
resource "aws_iam_role" "karpenter_node" {
  name = "${var.project_name}-${var.environment}-karpenter-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-karpenter-node"
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_node_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
  ])

  policy_arn = each.value
  role       = aws_iam_role.karpenter_node.name
}

resource "aws_iam_instance_profile" "karpenter_node" {
  name = "${var.project_name}-${var.environment}-karpenter-node"
  role = aws_iam_role.karpenter_node.name

  tags = var.common_tags
}

# ------------------------------------------------------------------------------
# Karpenter Helm Release
# ------------------------------------------------------------------------------
resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_version

  set {
    name  = "settings.clusterName"
    value = aws_eks_cluster.main.name
  }

  set {
    name  = "settings.clusterEndpoint"
    value = aws_eks_cluster.main.endpoint
  }

  set {
    name  = "serviceAccount.annotations.eks\.amazonaws\.com/role-arn"
    value = aws_iam_role.karpenter_controller.arn
  }

  set {
    name  = "settings.interruptionQueue"
    value = aws_sqs_queue.karpenter_interruption.name
  }

  depends_on = [aws_eks_cluster.main]
}

# ------------------------------------------------------------------------------
# Karpenter Interruption SQS Queue
# ------------------------------------------------------------------------------
resource "aws_sqs_queue" "karpenter_interruption" {
  name = "${var.project_name}-${var.environment}-karpenter-interruption"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-karpenter-interruption"
  })
}

# ------------------------------------------------------------------------------
# NodePool & EC2NodeClass Manifests
# ------------------------------------------------------------------------------
resource "kubernetes_manifest" "karpenter_node_class" {
  manifest = {
    apiVersion = "karpenter.k8s.aws/v1beta1"
    kind       = "EC2NodeClass"
    metadata = {
      name = "default"
    }
    spec = {
      amiFamily = "AL2"
      role      = aws_iam_role.karpenter_node.name
      subnetSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = aws_eks_cluster.main.name
          }
        }
      ]
      securityGroupSelectorTerms = [
        {
          tags = {
            "karpenter.sh/discovery" = aws_eks_cluster.main.name
          }
        }
      ]
      amiSelectorTerms = [
        {
          alias = "al2@${var.cluster_version}"
        }
      ]
      blockDeviceMappings = [
        {
          deviceName = "/dev/xvda"
          ebs = {
            volumeSize = "100Gi"
            volumeType = "gp3"
            iops       = 3000
            encrypted  = true
            kmsKeyID   = aws_kms_key.eks.arn
          }
        }
      ]
      detailedMonitoring = true
      metadataOptions = {
        httpEndpoint            = "enabled"
        httpProtocolIPv6        = "disabled"
        httpPutResponseHopLimit = 1
        httpTokens              = "required"
      }
    }
  }

  depends_on = [helm_release.karpenter]
}

resource "kubernetes_manifest" "karpenter_nodepool_spot" {
  manifest = {
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = {
      name = "spot-general"
    }
    spec = {
      template = {
        spec = {
          nodeClassRef = {
            name = "default"
          }
          requirements = [
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["spot"]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64", "arm64"]
            },
            {
              key      = "node.kubernetes.io/instance-type"
              operator = "In"
              values   = ["t4g.medium", "t4g.large", "m6g.medium", "m6g.large", "c6g.medium", "c6g.large", "m6i.large", "c6i.large"]
            },
            {
              key      = "topology.kubernetes.io/zone"
              operator = "In"
              values   = slice(data.aws_availability_zones.available.names, 0, var.az_count)
            }
          ]
          taints = []
        }
      }
      limits = {
        cpu    = tostring(var.nodepool_limits_cpu)
        memory = "${tostring(var.nodepool_limits_memory)}Gi"
      }
      disruption = {
        consolidationPolicy = "WhenUnderutilized"
        expireAfter         = "720h"
      }
      weight = 10
    }
  }

  depends_on = [kubernetes_manifest.karpenter_node_class]
}

resource "kubernetes_manifest" "karpenter_nodepool_ondemand" {
  manifest = {
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = {
      name = "on-demand-critical"
    }
    spec = {
      template = {
        spec = {
          nodeClassRef = {
            name = "default"
          }
          requirements = [
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["on-demand"]
            },
            {
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64", "arm64"]
            },
            {
              key      = "node.kubernetes.io/instance-type"
              operator = "In"
              values   = ["t3.medium", "t3.large", "m6i.large", "m6i.xlarge", "c6i.large"]
            },
            {
              key      = "topology.kubernetes.io/zone"
              operator = "In"
              values   = slice(data.aws_availability_zones.available.names, 0, var.az_count)
            }
          ]
          taints = [
            {
              key    = "workload-type"
              value  = "critical"
              effect = "NoSchedule"
            }
          ]
        }
      }
      limits = {
        cpu    = tostring(floor(var.nodepool_limits_cpu / 4))
        memory = "${tostring(floor(var.nodepool_limits_memory / 4))}Gi"
      }
      disruption = {
        consolidationPolicy = "WhenEmpty"
        expireAfter         = "720h"
      }
      weight = 50
    }
  }

  depends_on = [kubernetes_manifest.karpenter_node_class]
}

resource "kubernetes_manifest" "karpenter_nodepool_gpu" {
  count = var.graviton3_percentage > 0 ? 1 : 0

  manifest = {
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = {
      name = "gpu-optional"
    }
    spec = {
      template = {
        spec = {
          nodeClassRef = {
            name = "default"
          }
          requirements = [
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["on-demand"]
            },
            {
              key      = "node.kubernetes.io/instance-type"
              operator = "In"
              values   = ["g5.xlarge", "g5.2xlarge"]
            },
            {
              key      = "topology.kubernetes.io/zone"
              operator = "In"
              values   = slice(data.aws_availability_zones.available.names, 0, var.az_count)
            }
          ]
          taints = [
            {
              key    = "nvidia.com/gpu"
              value  = "true"
              effect = "NoSchedule"
            }
          ]
        }
      }
      limits = {
        cpu    = "100"
        memory = "400Gi"
      }
      disruption = {
        consolidationPolicy = "WhenEmpty"
        expireAfter         = "720h"
      }
      weight = 100
    }
  }

  depends_on = [kubernetes_manifest.karpenter_node_class]
}

# Data source for AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# ------------------------------------------------------------------------------
# Tags for Karpenter Discovery
# ------------------------------------------------------------------------------
resource "aws_ec2_tag" "private_subnet_karpenter" {
  count = length(var.private_subnet_ids)

  resource_id = var.private_subnet_ids[count.index]
  key         = "karpenter.sh/discovery"
  value       = aws_eks_cluster.main.name
}

resource "aws_ec2_tag" "cluster_sg_karpenter" {
  resource_id = aws_security_group.cluster.id
  key         = "karpenter.sh/discovery"
  value       = aws_eks_cluster.main.name
}
