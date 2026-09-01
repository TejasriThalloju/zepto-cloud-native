#!/usr/bin/env bash

set -euo pipefail

REGION="${AWS_REGION:-ap-south-1}"

echo "Creating ECR repositories..."

aws ecr describe-repositories \
  --repository-names quickcart-api \
  --region "$REGION" >/dev/null 2>&1 || \
aws ecr create-repository \
  --repository-name quickcart-api \
  --region "$REGION"

aws ecr describe-repositories \
  --repository-names quickcart-web \
  --region "$REGION" >/dev/null 2>&1 || \
aws ecr create-repository \
  --repository-name quickcart-web \
  --region "$REGION"

echo ""
echo "ECR repositories:"
aws ecr describe-repositories \
  --region "$REGION" \
  --query 'repositories[*].repositoryUri' \
  --output table