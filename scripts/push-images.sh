#!/usr/bin/env bash

set -euo pipefail

REGION="${AWS_REGION:-ap-south-1}"
ACCOUNT_ID=$(aws sts get-caller-identity \
  --query Account \
  --output text)

ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "AWS Account: $ACCOUNT_ID"
echo "Region: $REGION"

echo "Logging into ECR..."

aws ecr get-login-password \
  --region "$REGION" | \
docker login \
  --username AWS \
  --password-stdin "$ECR_REGISTRY"

echo "Building backend..."

docker build \
  -t quickcart-api:latest \
  ./services/api

echo "Tagging backend..."

docker tag \
  quickcart-api:latest \
  "${ECR_REGISTRY}/quickcart-api:latest"

echo "Pushing backend..."

docker push \
  "${ECR_REGISTRY}/quickcart-api:latest"


echo "Building frontend..."

docker build \
  -t quickcart-web:latest \
  ./services/web

echo "Tagging frontend..."

docker tag \
  quickcart-web:latest \
  "${ECR_REGISTRY}/quickcart-web:latest"

echo "Pushing frontend..."

docker push \
  "${ECR_REGISTRY}/quickcart-web:latest"


echo ""
echo "======================================"
echo "Images pushed successfully"
echo "======================================"

echo "Backend:"
echo "${ECR_REGISTRY}/quickcart-api:latest"

echo ""
echo "Frontend:"
echo "${ECR_REGISTRY}/quickcart-web:latest"