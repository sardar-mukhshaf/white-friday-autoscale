# ------------------------------------------------------------------------------
# Autoscaling Module Outputs
# ------------------------------------------------------------------------------

output "overprovision_deployment_name" {
  description = "Name of the overprovision deployment"
  value       = kubernetes_deployment.overprovision.metadata[0].name
}

output "metrics_server_release_name" {
  description = "Name of the Metrics Server Helm release"
  value       = helm_release.metrics_server.name
}
