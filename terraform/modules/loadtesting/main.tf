# ------------------------------------------------------------------------------
# Load Testing Namespace with Resource Quotas
# ------------------------------------------------------------------------------
resource "kubernetes_namespace" "loadtesting" {
  metadata {
    name = var.test_namespace

    labels = {
      "istio-injection"    = "disabled"
      "pod-security.kubernetes.io/enforce" = "restricted"
    }
  }
}

resource "kubernetes_resource_quota" "loadtesting" {
  metadata {
    name      = "loadtesting-quota"
    namespace = kubernetes_namespace.loadtesting.metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"    = "100"
      "requests.memory" = "200Gi"
      "limits.cpu"      = "200"
      "limits.memory"   = "400Gi"
      "pods"            = "100"
    }
  }
}

# ------------------------------------------------------------------------------
# k6 Operator
# ------------------------------------------------------------------------------
resource "helm_release" "k6_operator" {
  namespace        = kubernetes_namespace.loadtesting.metadata[0].name
  create_namespace = false

  name       = "k6-operator"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "k6-operator"
  version    = "3.4.0"

  set {
    name  = "namespace.create"
    value = "false"
  }

  set {
    name  = "manager.resources.requests.cpu"
    value = "500m"
  }

  set {
    name  = "manager.resources.requests.memory"
    value = "256Mi"
  }
}

# ------------------------------------------------------------------------------
# Locust Helm Release
# ------------------------------------------------------------------------------
resource "helm_release" "locust" {
  namespace        = kubernetes_namespace.loadtesting.metadata[0].name
  create_namespace = false

  name       = "locust"
  repository = "https://charts.deliveryhero.io"
  chart      = "locust"
  version    = "0.31.5"

  set {
    name  = "worker.replicaCount"
    value = var.locust_workers
  }

  set {
    name  = "worker.resources.requests.cpu"
    value = "500m"
  }

  set {
    name  = "worker.resources.requests.memory"
    value = "512Mi"
  }

  set {
    name  = "master.resources.requests.cpu"
    value = "500m"
  }

  set {
    name  = "master.resources.requests.memory"
    value = "512Mi"
  }
}

# ------------------------------------------------------------------------------
# Network Policy for Load Testing Namespace
# ------------------------------------------------------------------------------
resource "kubernetes_network_policy" "loadtesting_default_deny" {
  metadata {
    name      = "default-deny"
    namespace = kubernetes_namespace.loadtesting.metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
  }
}

resource "kubernetes_network_policy" "loadtesting_allow_egress" {
  metadata {
    name      = "allow-egress"
    namespace = kubernetes_namespace.loadtesting.metadata[0].name
  }

  spec {
    pod_selector {}
    policy_types = ["Egress"]

    egress {
      to {
        namespace_selector {}
      }
      ports {
        port     = "80"
        protocol = "TCP"
      }
      ports {
        port     = "443"
        protocol = "TCP"
      }
    }
  }
}
