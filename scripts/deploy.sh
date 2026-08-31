#!/usr/bin/env bash
set -euo pipefail

REGION="${AWS_REGION:-ap-south-1}"
CLUSTER="${EKS_CLUSTER:-quickcart-eks}"
PROJECT="${PROJECT_NAME:-quickcart}"

echo "=========================================="
echo "QuickCart AWS Deployment"
echo "Region  : $REGION"
echo "Cluster : $CLUSTER"
echo "=========================================="

# ----------------------------------------
# 1. Check AWS authentication
# ----------------------------------------

echo "Checking AWS authentication..."

aws sts get-caller-identity

echo "AWS authentication successful."


# ----------------------------------------
# 2. Check required tools
# ----------------------------------------

command -v aws >/dev/null 2>&1 || {
  echo "ERROR: AWS CLI is not installed."
  exit 1
}

command -v kubectl >/dev/null 2>&1 || {
  echo "ERROR: kubectl is not installed."
  exit 1
}

command -v helm >/dev/null 2>&1 || {
  echo "ERROR: Helm is not installed."
  exit 1
}


# ----------------------------------------
# 3. Create EKS cluster if it doesn't exist
# ----------------------------------------

if aws eks describe-cluster \
  --region "$REGION" \
  --name "$CLUSTER" \
  >/dev/null 2>&1; then

  echo "EKS cluster '$CLUSTER' already exists."

else

  echo "EKS cluster '$CLUSTER' does not exist."
  echo "Creating EKS cluster..."

  command -v eksctl >/dev/null 2>&1 || {
    echo "ERROR: eksctl is required to create the EKS cluster."
    echo "Install eksctl and run the script again."
    exit 1
  }

  eksctl create cluster \
    --name "$CLUSTER" \
    --region "$REGION" \
    --nodegroup-name "${PROJECT}-nodes" \
    --node-type t3.medium \
    --nodes 2 \
    --nodes-min 2 \
    --nodes-max 4 \
    --managed

  echo "EKS cluster created successfully."
fi


# ----------------------------------------
# 4. Update kubeconfig
# ----------------------------------------

echo "Updating kubeconfig..."

aws eks update-kubeconfig \
  --region "$REGION" \
  --name "$CLUSTER"

echo "Checking Kubernetes nodes..."

kubectl get nodes


# ----------------------------------------
# 5. Install NGINX Ingress Controller
# ----------------------------------------

echo "Installing NGINX Ingress Controller..."

helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --wait


# ----------------------------------------
# 6. Deploy QuickCart application
# ----------------------------------------

echo "Deploying QuickCart..."

helm upgrade --install quickcart deploy/helm/quickcart \
  --namespace quickcart \
  --create-namespace \
  -f deploy/helm/quickcart/values-prod.yaml \
  --wait


# ----------------------------------------
# 7. Wait for API deployment
# ----------------------------------------

echo "Waiting for QuickCart API..."

kubectl rollout status \
  deployment/quickcart-api \
  -n quickcart \
  --timeout=5m


# ----------------------------------------
# 8. Wait for Web deployment
# ----------------------------------------

echo "Waiting for QuickCart Web..."

kubectl rollout status \
  deployment/quickcart-web \
  -n quickcart \
  --timeout=5m


# ----------------------------------------
# 9. Show application status
# ----------------------------------------

echo "=========================================="
echo "Deployment Status"
echo "=========================================="

kubectl get pods -n quickcart

echo ""

kubectl get svc -n quickcart

echo ""

kubectl get ingress -n quickcart


echo "=========================================="
echo "QuickCart deployment completed!"
echo "=========================================="