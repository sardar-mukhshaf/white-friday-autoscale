# ------------------------------------------------------------------------------
# Observability Module Outputs
# ------------------------------------------------------------------------------

output "monitoring_namespace" {
  description = "Namespace for monitoring"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "grafana_release_name" {
  description = "Name of the Grafana Helm release"
  value       = helm_release.kube_prometheus_stack.name
}

output "jaeger_release_name" {
  description = "Name of the Jaeger Helm release"
  value       = var.enable_jaeger ? helm_release.jaeger[0].name : null
}
