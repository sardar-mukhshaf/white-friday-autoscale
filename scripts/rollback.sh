#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# Automated Rollback
# Reverts deployment on SLO breach using ArgoCD or kubectl
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="${PROJECT_NAME:-whitefriday}"
ENVIRONMENT="${ENVIRONMENT:-staging}"
NAMESPACE="${NAMESPACE:-default}"
SLO_AVAILABILITY="${SLO_AVAILABILITY:-0.999}"
SLO_LATENCY_MS="${SLO_LATENCY_MS:-200}"

echo "========================================"
echo "White Friday Automated Rollback"
echo "Environment: ${ENVIRONMENT}"
echo "SLO Availability: ${SLO_AVAILABILITY}"
echo "SLO Latency: ${SLO_LATENCY_MS}ms"
echo "========================================"

# Query Prometheus for SLO metrics
echo ""
echo "Querying SLO metrics from Prometheus..."

AVAILABILITY=$(kubectl exec -n monitoring deployment/prometheus -- \
  wget -qO- "http://localhost:9090/api/v1/query?query=1-sum(rate(http_requests_total{status=~\"5..\"}[5m]))/sum(rate(http_requests_total[5m]))" 2>/dev/null | \
  jq -r '.data.result[0].value[1]' || echo "1")

P95_LATENCY=$(kubectl exec -n monitoring deployment/prometheus -- \
  wget -qO- "http://localhost:9090/api/v1/query?query=histogram_quantile(0.95,sum(rate(http_request_duration_seconds_bucket[5m]))by(le))" 2>/dev/null | \
  jq -r '.data.result[0].value[1]' || echo "0")

P95_LATENCY_MS=$(echo "${P95_LATENCY} * 1000" | bc -l)

echo "Current Availability: ${AVAILABILITY}"
echo "Current p(95) Latency: ${P95_LATENCY_MS}ms"

BREACH=0

if (( $(echo "${AVAILABILITY} < ${SLO_AVAILABILITY}" | bc -l) )); then
  echo "SLO BREACH: Availability ${AVAILABILITY} < ${SLO_AVAILABILITY}"
  BREACH=1
fi

if (( $(echo "${P95_LATENCY_MS} > ${SLO_LATENCY_MS}" | bc -l) )); then
  echo "SLO BREACH: Latency ${P95_LATENCY_MS}ms > ${SLO_LATENCY_MS}ms"
  BREACH=1
fi

if [ "${BREACH}" -eq 0 ]; then
  echo ""
  echo "All SLOs healthy. No rollback needed."
  exit 0
fi

echo ""
echo "========================================"
echo "INITIATING ROLLBACK"
echo "========================================"

# Rollback all microservices
SERVICES=("frontend" "product-service" "cart-service" "order-service" "payment-service")

for SERVICE in "${SERVICES[@]}"; do
  echo ""
  echo "Rolling back ${SERVICE}..."

  # Check if ArgoCD is available
  if command -v argocd &>/dev/null && argocd app list 2>/dev/null | grep -q "${SERVICE}"; then
    argocd app rollback "${SERVICE}" 0
    echo "  ArgoCD rollback initiated for ${SERVICE}."
  else
    # Fallback to kubectl rollout undo
    if kubectl rollout history deployment/"${SERVICE}" -n "${NAMESPACE}" 2>/dev/null | tail -n +2 | wc -l | grep -q "[2-9]"; then
      kubectl rollout undo deployment/"${SERVICE}" -n "${NAMESPACE}"
      echo "  kubectl rollback initiated for ${SERVICE}."
    else
      echo "  WARNING: No previous revision found for ${SERVICE}."
    fi
  fi
done

# Wait for rollouts to complete
echo ""
echo "Waiting for rollouts to complete..."
for SERVICE in "${SERVICES[@]}"; do
  kubectl rollout status deployment/"${SERVICE}" -n "${NAMESPACE}" --timeout=300s || true
done

echo ""
echo "========================================"
echo "Rollback complete."
echo "========================================"
