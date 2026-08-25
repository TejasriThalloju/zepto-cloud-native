# QuickCart — Cloud-Native Grocery Delivery Demo

A production-style learning project inspired by a quick-commerce grocery app. It is **not Zepto's source code** and does not use Zepto branding/assets.

## Architecture

Browser → NGINX Ingress → React frontend + FastAPI API → PostgreSQL (RDS) + Redis (ElastiCache)
                                           └→ S3
EKS is provisioned with Terraform. Docker images go to ECR. GitHub Actions builds/tests/scans/pushes/deploys with Helm.
Prometheus/Grafana are included for observability.

## Features

- Product catalog and search
- Shopping cart
- Checkout/order creation
- Order status tracking
- WebSocket order-status updates
- PostgreSQL persistence
- Redis cache
- Docker + ECR
- EKS + Helm
- Terraform VPC/EKS/RDS/ElastiCache/S3
- GitHub Actions CI/CD
- Prometheus/Grafana
- Kubernetes security examples, probes, HPA, PDB, NetworkPolicy

## Local run

```bash
docker compose up --build
```

Open http://localhost:5173

API: http://localhost:8000/docs

## AWS deployment

1. Configure AWS credentials and create an S3 backend for Terraform state.
2. Edit `infra/terraform/terraform.tfvars`.
3. Run:
```bash
cd infra/terraform
terraform init
terraform apply
```
4. Create ECR repositories and push images:
```bash
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com
```
5. Update Helm values with the ECR image URLs and database/Redis settings.
6. Install ingress:
```bash
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```
7. Deploy:
```bash
helm upgrade --install quickcart ./deploy/helm/quickcart \
  --namespace quickcart --create-namespace \
  -f deploy/helm/quickcart/values-prod.yaml
```

## Important production hardening

This repository is intentionally suitable for learning/interview/demo use. Before production, add:
- AWS Secrets Manager + External Secrets Operator
- private RDS/Redis subnets and restricted SGs
- WAF/CloudFront
- TLS with ACM/cert-manager
- image signing/SBOM
- centralized logs
- backups and restore testing
- payment provider integration
- idempotency keys and transactional outbox
- multi-AZ node groups and database
- rate limiting and stronger authentication

## Deployment guide
See `AWS-DEPLOYMENT-STEPS.md` for the exact AWS/GitHub sequence.
