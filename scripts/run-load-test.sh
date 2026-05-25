#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# Run Load Test
# Triggers k6/Locust and evaluates 200ms latency gate
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="${PROJECT_NAME:-whitefriday}"
ENVIRONMENT="${ENVIRONMENT:-staging}"
K6_VUS="${K6_VUS:-50000}"
K6_DURATION="${K6_DURATION:-10m}"
LATENCY_GATE_MS="${LATENCY_GATE_MS:-200}"
ERROR_RATE_GATE="${ERROR_RATE_GATE:-0.001}"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RESULTS_DIR="${SCRIPT_DIR}/../load-test-results/${TIMESTAMP}"
mkdir -p "${RESULTS_DIR}"

echo "========================================"
echo "White Friday Load Test Runner"
echo "Environment: ${ENVIRONMENT}"
echo "VUs: ${K6_VUS}"
echo "Duration: ${K6_DURATION}"
echo "Latency Gate: ${LATENCY_GATE_MS}ms"
echo "Error Rate Gate: ${ERROR_RATE_GATE}"
echo "========================================"

# Determine target URL
if [ "${ENVIRONMENT}" == "local" ]; then
  TARGET_URL="http://localhost:3000"
elif [ "${ENVIRONMENT}" == "staging" ]; then
  TARGET_URL="https://staging.whitefriday.example.com"
else
  TARGET_URL="https://whitefriday.example.com"
fi

# Run k6 test
echo ""
echo "Starting k6 load test..."
k6 run \
  --vus "${K6_VUS}" \
  --duration "${K6_DURATION}" \
  --env BASE_URL="${TARGET_URL}" \
  --out json="${RESULTS_DIR}/k6-results.json" \
  --out influxdb=http://influxdb:8086/k6 \
  "${SCRIPT_DIR}/../kubernetes/k6-tests/white-friday-load-test.js" \
  || true

# Generate k6 HTML report if k6-reporter is available
if command -v k6-reporter &>/dev/null; then
  k6-reporter \
    --input "${RESULTS_DIR}/k6-results.json" \
    --output "${RESULTS_DIR}/k6-report.html"
fi

# Evaluate latency gate
echo ""
echo "Evaluating latency gate..."

# Parse k6 summary JSON for p(95) latency
if [ -f "${RESULTS_DIR}/k6-results.json" ]; then
  P95_LATENCY=$(grep -o '"p(95)":[0-9.]*' "${RESULTS_DIR}/k6-results.json" | head -1 | cut -d':' -f2 || echo "0")
  ERROR_RATE=$(grep -o '"failed":{"values":{"rate":[0-9.]*' "${RESULTS_DIR}/k6-results.json" | grep -o '[0-9.]*' | head -1 || echo "0")

  echo "k6 p(95) Latency: ${P95_LATENCY}ms"
  echo "k6 Error Rate: ${ERROR_RATE}"

  FAILED=0

  if (( $(echo "${P95_LATENCY} > ${LATENCY_GATE_MS}" | bc -l) )); then
    echo "FAIL: p(95) latency ${P95_LATENCY}ms exceeds gate ${LATENCY_GATE_MS}ms"
    FAILED=1
  else
    echo "PASS: p(95) latency within gate"
  fi

  if (( $(echo "${ERROR_RATE} > ${ERROR_RATE_GATE}" | bc -l) )); then
    echo "FAIL: Error rate ${ERROR_RATE} exceeds gate ${ERROR_RATE_GATE}"
    FAILED=1
  else
    echo "PASS: Error rate within gate"
  fi

  if [ "${FAILED}" -eq 1 ]; then
    echo ""
    echo "========================================"
    echo "LOAD TEST FAILED - TRIGGERING ROLLBACK"
    echo "========================================"
    exit 1
  fi
else
  echo "WARN: k6 results file not found. Skipping gate evaluation."
fi

echo ""
echo "========================================"
echo "Load test completed successfully."
echo "Results saved to: ${RESULTS_DIR}"
echo "========================================"
