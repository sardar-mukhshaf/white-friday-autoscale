#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# Bootstrap Terraform Backend (S3 + DynamoDB)
# Idempotent creation of remote state resources
# ------------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="${PROJECT_NAME:-whitefriday}"
REGION="${AWS_REGION:-eu-west-1}"
BUCKET_NAME="${PROJECT_NAME}-terraform-state"
DYNAMODB_TABLE="${PROJECT_NAME}-terraform-locks"

echo "========================================"
echo "Bootstrapping Terraform Backend"
echo "Project: ${PROJECT_NAME}"
echo "Region:  ${REGION}"
echo "========================================"

# Check AWS credentials
if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo "ERROR: AWS credentials not configured or invalid."
  exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: ${ACCOUNT_ID}"

# Create S3 bucket if not exists
echo "Checking S3 bucket: ${BUCKET_NAME}"
if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
  echo "S3 bucket already exists."
else
  echo "Creating S3 bucket..."
  if [ "${REGION}" == "us-east-1" ]; then
    aws s3api create-bucket --bucket "${BUCKET_NAME}"
  else
    aws s3api create-bucket \
      --bucket "${BUCKET_NAME}" \
      --create-bucket-configuration LocationConstraint="${REGION}"
  fi

  aws s3api put-bucket-versioning \
    --bucket "${BUCKET_NAME}" \
    --versioning-configuration Status=Enabled

  aws s3api put-bucket-encryption \
    --bucket "${BUCKET_NAME}" \
    --server-side-encryption-configuration '{
      "Rules": [{
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }]
    }'

  aws s3api put-public-access-block \
    --bucket "${BUCKET_NAME}" \
    --public-access-block-configuration \
      BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

  echo "S3 bucket created and configured."
fi

# Create DynamoDB table if not exists
echo "Checking DynamoDB table: ${DYNAMODB_TABLE}"
if aws dynamodb describe-table --table-name "${DYNAMODB_TABLE}" >/dev/null 2>&1; then
  echo "DynamoDB table already exists."
else
  echo "Creating DynamoDB table..."
  aws dynamodb create-table \
    --table-name "${DYNAMODB_TABLE}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST

  echo "DynamoDB table created."
fi

echo "========================================"
echo "Backend bootstrap complete!"
echo "Update backend.tf with:"
echo "  bucket = ${BUCKET_NAME}"
echo "  dynamodb_table = ${DYNAMODB_TABLE}"
echo "  region = ${REGION}"
echo "========================================"
