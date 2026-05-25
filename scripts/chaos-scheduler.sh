#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# Chaos Scheduler
# Runs Litmus experiments in staging with safety checks
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="${PROJECT_NAME:-whitefriday}"
ENVIRONMENT="${ENVIRONMENT:-staging}"
CHAOS_NAMESPACE="${CHAOS_NAMESPACE:-litmus}"
MAX_ERROR_RATE="${MAX_ERROR_RATE:-0.05}"

echo "========================================"
echo "White Friday Chaos Scheduler"
echo "Environment: ${ENVIRONMENT}"
echo "Max Error Rate: ${MAX_ERROR_RATE}"
echo "========================================"

# Safety check: only run in staging/chaos environments
if [ "${ENVIRONMENT}" == "prod" ]; then
  echo "ERROR: Chaos experiments are BLOCKED in production."
  exit 1
fi

# Check cluster connectivity
if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "ERROR: Cannot connect to Kubernetes cluster."
  exit 1
fi

# Check Litmus operator
if ! kubectl get deployment -n "${CHAOS_NAMESPACE}" litmus-chaos-operator >/dev/null 2>&1; then
  echo "ERROR: Litmus operator not found in namespace ${CHAOS_NAMESPACE}."
  exit 1
fi

# Pre-chaos health check
echo ""
echo "Running pre-chaos health check..."
CURRENT_ERROR_RATE=$(kubectl exec -n monitoring deployment/prometheus -- \
  wget -qO- 'http://localhost:9090/api/v1/query?query=sum(rate(http_requests_total{status=~"5.."}[5m]))/sum(rate(http_requests_total[5m]))' 2>/dev/null | \
  jq -r '.data.result[0].value[1]' || echo "0")

echo "Current error rate: ${CURRENT_ERROR_RATE}"

if (( $(echo "${CURRENT_ERROR_RATE} > ${MAX_ERROR_RATE}" | bc -l) )); then
  echo "ERROR: Current error rate ${CURRENT_ERROR_RATE} exceeds threshold ${MAX_ERROR_RATE}."
  echo "Aborting chaos experiment for safety."
  exit 1
fi

# Apply chaos experiments
echo ""
echo "Applying chaos experiments..."
kubectl apply -f "${SCRIPT_DIR}/../kubernetes/litmus/pod-delete.yaml"
kubectl apply -f "${SCRIPT_DIR}/../kubernetes/litmus/network-latency.yaml"

# Monitor during chaos
echo ""
echo "Monitoring for 15 minutes..."
for i in {1..90}; do
  sleep 10
  ERROR_RATE=$(kubectl exec -n monitoring deployment/prometheus -- \
    wget -qO- 'http://localhost:9090/api/v1/query?query=sum(rate(http_requests_total{status=~"5.."}[2m]))/sum(rate(http_requests_total[2m]))' 2>/dev/null | \
    jq -r '.data.result[0].value[1]' || echo "0")

  echo "  [${i}/90] Error rate: ${ERROR_RATE}"

  if (( $(echo "${ERROR_RATE} > ${MAX_ERROR_RATE}" | bc -l) )); then
    echo ""
    echo "WARNING: Error rate ${ERROR_RATE} exceeded threshold ${MAX_ERROR_RATE}."
    echo "Aborting chaos experiments..."

    kubectl delete chaosengine -n "${CHAOS_NAMESPACE}" --all --wait=false
    echo "Chaos experiments aborted."
    exit 1
  fi
done

# Post-chaos cleanup
echo ""
echo "Chaos experiment duration complete. Cleaning up..."
kubectl delete chaosengine -n "${CHAOS_NAMESPACE}" --all --wait=false

# Post-chaos health check
echo ""
echo "Running post-chaos health check..."
FINAL_ERROR_RATE=$(kubectl exec -n monitoring deployment/prometheus -- \
  wget -qO- 'http://localhost:9090/api/v1/query?query=sum(rate(http_requests_total{status=~"5.."}[5m]))/sum(rate(http_requests_total[5m]))' 2>/dev/null | \
  jq -r '.data.result[0].value[1]' || echo "0")

echo "Final error rate: ${FINAL_ERROR_RATE}"

if (( $(echo "${FINAL_ERROR_RATE} > ${MAX_ERROR_RATE}" | bc -l) )); then
  echo "ERROR: System did not recover to acceptable error rate."
  exit 1
fi

echo ""
echo "========================================"
echo "Chaos engineering session completed."
echo "System recovered successfully."
echo "========================================"
