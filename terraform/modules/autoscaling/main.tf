# ------------------------------------------------------------------------------
# Over-provisioning Pause Pods
# ------------------------------------------------------------------------------
resource "kubernetes_priority_class" "overprovision" {
  metadata {
    name = "overprovision"
  }

  value          = -1
  preemption_policy = "Never"
  global_default = false
  description    = "Priority class for over-provisioning pause pods"
}

resource "kubernetes_deployment" "overprovision" {
  metadata {
    name      = "overprovision"
    namespace = "kube-system"
    labels = {
      app = "overprovision"
    }
  }

  spec {
    replicas = var.overprovision_replicas

    selector {
      match_labels = {
        app = "overprovision"
      }
    }

    template {
      metadata {
        labels = {
          app = "overprovision"
        }
      }

      spec {
        priority_class_name = kubernetes_priority_class.overprovision.metadata[0].name
        container {
          name    = "pause"
          image   = "registry.k8s.io/pause:3.9"
          command = ["pause"]

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "100m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}

# ------------------------------------------------------------------------------
# Cluster Proportional Autoscaler for CoreDNS
# ------------------------------------------------------------------------------
resource "helm_release" "cluster_proportional_autoscaler" {
  namespace  = "kube-system"
  name       = "cluster-proportional-autoscaler"
  repository = "https://kubernetes-sigs.github.io/cluster-proportional-autoscaler"
  chart      = "cluster-proportional-autoscaler"
  version    = "1.1.0"

  set {
    name  = "config.name"
    value = "coredns"
  }

  set {
    name  = "config.namespace"
    value = "kube-system"
  }

  set {
    name  = "config.target"
    value = "deployment/coredns"
  }

  set {
    name  = "config.min"
    value = "2"
  }

  set {
    name  = "config.max"
    value = "20"
  }

  set {
    name  = "config.coresPerReplica"
    value = "128"
  }

  set {
    name  = "config.nodesPerReplica"
    value = "4"
  }

  set {
    name  = "config.preventSinglePointFailure"
    value = "true"
  }
}

# ------------------------------------------------------------------------------
# Metrics Server (required for HPA)
# ------------------------------------------------------------------------------
resource "helm_release" "metrics_server" {
  namespace  = "kube-system"
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io.metrics-server"
  chart      = "metrics-server"
  version    = "3.11.0"

  set {
    name  = "args[0]"
    value = "--kubelet-insecure-tls"
  }

  set {
    name  = "args[1]"
    value = "--metric-resolution=15s"
  }
}

# ------------------------------------------------------------------------------
# Vertical Pod Autoscaler (VPA) - Off mode for recommendations
# ------------------------------------------------------------------------------
resource "helm_release" "vpa" {
  count = var.environment == "staging" ? 1 : 0

  namespace  = "kube-system"
  name       = "vertical-pod-autoscaler"
  repository = "https://cowboysysop.github.io/charts"
  chart      = "vertical-pod-autoscaler"
  version    = "9.4.0"

  set {
    name  = "recommender.enabled"
    value = "true"
  }

  set {
    name  = "updater.enabled"
    value = "false"
  }

  set {
    name  = "admissionController.enabled"
    value = "false"
  }
}
