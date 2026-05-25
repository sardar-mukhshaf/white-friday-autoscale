# ------------------------------------------------------------------------------
# Providers
# ------------------------------------------------------------------------------
terraform {
  required_version = "~> 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~> 16.7"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.common_tags
  }
}

provider "kubernetes" {
  host                   = module.eks_karpenter.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_karpenter.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.main.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks_karpenter.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_karpenter.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}
