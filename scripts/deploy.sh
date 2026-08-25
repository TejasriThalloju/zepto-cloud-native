#!/usr/bin/env bash
set -euo pipefail
REGION="${AWS_REGION:-ap-south-1}"
CLUSTER="${EKS_CLUSTER:-quickcart-eks}"

aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER"

helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace

helm upgrade --install quickcart deploy/helm/quickcart \
  --namespace quickcart --create-namespace \
  -f deploy/helm/quickcart/values-prod.yaml

kubectl rollout status deployment/quickcart-api -n quickcart --timeout=5m
kubectl rollout status deployment/quickcart-web -n quickcart --timeout=5m
kubectl get ingress -n quickcart
