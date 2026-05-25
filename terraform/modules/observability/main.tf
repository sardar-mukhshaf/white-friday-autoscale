# ------------------------------------------------------------------------------
# Prometheus + Grafana (kube-prometheus-stack)
# ------------------------------------------------------------------------------
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"

    labels = {
      "pod-security.kubernetes.io/enforce" = "baseline"
    }
  }
}

resource "helm_release" "kube_prometheus_stack" {
  namespace        = kubernetes_namespace.monitoring.metadata[0].name
  create_namespace = false

  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "55.5.0"

  set {
    name  = "grafana.admin.existingSecret"
    value = var.grafana_admin_password_secret
  }

  set {
    name  = "grafana.persistence.enabled"
    value = "true"
  }

  set {
    name  = "grafana.persistence.size"
    value = "10Gi"
  }

  set {
    name  = "prometheus.prometheusSpec.retention"
    value = "${var.retention_days}d"
  }

  set {
    name  = "prometheus.prometheusSpec.persistence.enabled"
    value = "true"
  }

  set {
    name  = "prometheus.prometheusSpec.persistence.size"
    value = "50Gi"
  }

  set {
    name  = "alertmanager.enabled"
    value = "true"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.retention"
    value = "120h"
  }

  values = [
    <<-EOT
    grafana:
      dashboardProviders:
        dashboardproviders.yaml:
          apiVersion: 1
          providers:
            - name: 'default'
              orgId: 1
              folder: ''
              type: file
              disableDeletion: false
              editable: true
              options:
                path: /var/lib/grafana/dashboards/default
      dashboards:
        default:
          karpenter-efficiency:
            url: https://raw.githubusercontent.com/aws/karpenter-provider-aws/main/charts/karpenter/dashboards/karpenter-efficiency.json
      additionalDataSources:
        - name: CloudWatch
          type: cloudwatch
          jsonData:
            authType: credentials
            defaultRegion: ${var.region}
    EOT
  ]
}

# ------------------------------------------------------------------------------
# Jaeger (conditional)
# ------------------------------------------------------------------------------
resource "helm_release" "jaeger" {
  count = var.enable_jaeger ? 1 : 0

  namespace        = kubernetes_namespace.monitoring.metadata[0].name
  create_namespace = false

  name       = "jaeger"
  repository = "https://jaegertracing.github.io/helm-charts"
  chart      = "jaeger"
  version    = "0.71.18"

  set {
    name  = "provisionDataStore.cassandra"
    value = "false"
  }

  set {
    name  = "storage.type"
    value = "memory"
  }

  set {
    name  = "agent.enabled"
    value = "false"
  }

  set {
    name  = "allInOne.enabled"
    value = "true"
  }
}

# ------------------------------------------------------------------------------
# CloudWatch Container Insights (via Helm)
# ------------------------------------------------------------------------------
resource "helm_release" "aws_cloudwatch_agent" {
  namespace  = "amazon-cloudwatch"
  name       = "aws-cloudwatch-agent"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-cloudwatch-metrics"
  version    = "0.0.9"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "enhancedContainerInsights"
    value = "true"
  }
}

# ------------------------------------------------------------------------------
# Prometheus Adapter for HPA Custom Metrics
# ------------------------------------------------------------------------------
resource "helm_release" "prometheus_adapter" {
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  name       = "prometheus-adapter"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus-adapter"
  version    = "4.9.0"

  set {
    name  = "prometheus.url"
    value = "http://kube-prometheus-stack-prometheus"
  }

  set {
    name  = "prometheus.port"
    value = "9090"
  }

  values = [
    <<-EOT
    rules:
      custom:
        - seriesQuery: 'http_requests_total{namespace!="",pod!=""}'
          resources:
            template: <<.Resource>>
          name:
            matches: "^(.*)_total"
            as: "${1}_per_second"
          metricsQuery: 'sum(rate(<<.Series>>{<<.LabelMatchers>>}[1m])) by (<<.GroupBy>>)'
    EOT
  ]
}
