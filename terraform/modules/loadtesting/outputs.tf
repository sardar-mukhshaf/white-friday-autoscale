# ------------------------------------------------------------------------------
# Load Testing Module Outputs
# ------------------------------------------------------------------------------

output "test_namespace" {
  description = "Namespace for load testing"
  value       = kubernetes_namespace.loadtesting.metadata[0].name
}

output "k6_operator_release_name" {
  description = "Name of the k6 operator Helm release"
  value       = helm_release.k6_operator.name
}

output "locust_release_name" {
  description = "Name of the Locust Helm release"
  value       = helm_release.locust.name
}
