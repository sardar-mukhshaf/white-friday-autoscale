# ------------------------------------------------------------------------------
# Chaos Engineering Module Outputs
# ------------------------------------------------------------------------------

output "chaos_namespace" {
  description = "Namespace for chaos engineering"
  value       = var.enable_chaos ? kubernetes_namespace.chaos[0].metadata[0].name : null
}

output "litmus_release_name" {
  description = "Name of the Litmus Helm release"
  value       = var.enable_chaos ? helm_release.litmus[0].name : null
}
