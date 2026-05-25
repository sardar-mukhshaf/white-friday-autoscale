# ------------------------------------------------------------------------------
# LitmusChaos Namespace
# ------------------------------------------------------------------------------
resource "kubernetes_namespace" "chaos" {
  count = var.enable_chaos ? 1 : 0

  metadata {
    name = var.chaos_namespace

    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

# ------------------------------------------------------------------------------
# LitmusChaos Helm Release
# ------------------------------------------------------------------------------
resource "helm_release" "litmus" {
  count = var.enable_chaos ? 1 : 0

  namespace        = kubernetes_namespace.chaos[0].metadata[0].name
  create_namespace = false

  name       = "litmus"
  repository = "https://litmuschaos.github.io/litmus-helm"
  chart      = "litmus"
  version    = "3.0.0"

  set {
    name  = "portal.frontend.service.type"
    value = "ClusterIP"
  }

  set {
    name  = "portal.server.service.type"
    value = "ClusterIP"
  }
}

# ------------------------------------------------------------------------------
# LitmusChaos Operator Helm Release
# ------------------------------------------------------------------------------
resource "helm_release" "litmus_chaos_operator" {
  count = var.enable_chaos ? 1 : 0

  namespace        = kubernetes_namespace.chaos[0].metadata[0].name
  create_namespace = false

  name       = "litmus-core"
  repository = "https://litmuschaos.github.io/litmus-helm"
  chart      = "litmus-core"
  version    = "3.0.0"
}

# ------------------------------------------------------------------------------
# Service Account for Chaos Experiments
# ------------------------------------------------------------------------------
resource "kubernetes_service_account" "chaos" {
  count = var.enable_chaos ? 1 : 0

  metadata {
    name      = "litmus-admin"
    namespace = kubernetes_namespace.chaos[0].metadata[0].name
  }
}

resource "kubernetes_cluster_role_binding" "chaos" {
  count = var.enable_chaos ? 1 : 0

  metadata {
    name = "litmus-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.chaos[0].metadata[0].name
    namespace = kubernetes_namespace.chaos[0].metadata[0].name
  }
}
