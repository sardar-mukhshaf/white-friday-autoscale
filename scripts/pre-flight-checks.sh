#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# Pre-flight Checks
# Validates AWS credentials, quotas, and required tools before deployment
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="${PROJECT_NAME:-whitefriday}"
REGION="${AWS_REGION:-eu-west-1}"
ENVIRONMENT="${ENVIRONMENT:-dev}"

ERRORS=0

echo "========================================"
echo "White Friday Pre-flight Checks"
echo "========================================"

# Check AWS CLI
if ! command -v aws &>/dev/null; then
  echo "ERROR: AWS CLI not found."
  ERRORS=$((ERRORS + 1))
else
  echo "[OK] AWS CLI found: $(aws --version)"
fi

# Check Terraform
if ! command -v terraform &>/dev/null; then
  echo "ERROR: Terraform not found."
  ERRORS=$((ERRORS + 1))
else
  echo "[OK] Terraform found: $(terraform version -json | jq -r '.terraform_version')"
fi

# Check kubectl
if ! command -v kubectl &>/dev/null; then
  echo "WARN: kubectl not found (needed for K8s validation)."
else
  echo "[OK] kubectl found: $(kubectl version --client -o json | jq -r '.clientVersion.gitVersion')"
fi

# Check Docker Buildx
if ! docker buildx version &>/dev/null; then
  echo "WARN: Docker Buildx not found (needed for multi-arch builds)."
else
  echo "[OK] Docker Buildx found."
fi

# Check AWS credentials
echo ""
echo "Checking AWS credentials..."
if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo "ERROR: AWS credentials not configured or invalid."
  ERRORS=$((ERRORS + 1))
else
  CALLER=$(aws sts get-caller-identity --output json)
  ACCOUNT_ID=$(echo "$CALLER" | jq -r '.Account')
  ARN=$(echo "$CALLER" | jq -r '.Arn')
  echo "[OK] AWS credentials valid."
  echo "     Account: ${ACCOUNT_ID}"
  echo "     ARN: ${ARN}"
fi

# Check EKS cluster quota
echo ""
echo "Checking EKS cluster quota..."
EKS_CLUSTERS=$(aws eks list-clusters --region "${REGION}" --query 'clusters[]' --output text | wc -w)
echo "     Current EKS clusters in ${REGION}: ${EKS_CLUSTERS}"
if [ "${EKS_CLUSTERS}" -ge 10 ]; then
  echo "WARN: Approaching EKS cluster quota (10)."
fi

# Check VPC quota
echo ""
echo "Checking VPC quota..."
VPC_COUNT=$(aws ec2 describe-vpcs --region "${REGION}" --query 'Vpcs[]' --output text | wc -w)
echo "     Current VPCs in ${REGION}: ${VPC_COUNT}"
if [ "${VPC_COUNT}" -ge 20 ]; then
  echo "WARN: Approaching VPC quota (20)."
fi

# Check EC2 vCPU quotas
echo ""
echo "Checking EC2 vCPU quotas..."
for FAMILY in "L-1216C47A" "L-34B43A08"; do
  QUOTA=$(aws service-quotas get-service-quota \
    --service-code ec2 \
    --quota-code "${FAMILY}" \
    --region "${REGION}" \
    --query 'Quota.Value' \
    --output text 2>/dev/null || echo "unknown")
  echo "     Quota ${FAMILY}: ${QUOTA}"
done

# Check ECR storage
echo ""
echo "Checking ECR repositories..."
ECR_REPOS=$(aws ecr describe-repositories --region "${REGION}" --query 'repositories[]' --output text | wc -w)
echo "     Current ECR repos in ${REGION}: ${ECR_REPOS}"

# Check required IAM permissions (simulate)
echo ""
echo "Checking required IAM permissions..."
REQUIRED_ACTIONS=(
  "eks:CreateCluster"
  "ec2:CreateVpc"
  "rds:CreateDBCluster"
  "elasticache:CreateReplicationGroup"
  "wafv2:CreateWebACL"
  "kms:CreateKey"
)

for ACTION in "${REQUIRED_ACTIONS[@]}"; do
  # Note: Actual simulation requires iam:SimulatePrincipalPolicy
  echo "     [SKIP] ${ACTION} (run iam-policy-check for detailed validation)"
done

# Summary
echo ""
echo "========================================"
if [ "${ERRORS}" -eq 0 ]; then
  echo "Pre-flight checks PASSED."
  echo "Ready to deploy ${PROJECT_NAME} to ${ENVIRONMENT}."
else
  echo "Pre-flight checks FAILED with ${ERRORS} error(s)."
  exit 1
fi
echo "========================================"
