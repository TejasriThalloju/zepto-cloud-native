# Exact AWS Deployment Steps

## 1. Install locally (Windows)
Install AWS CLI v2, Terraform >= 1.15, kubectl, Helm, Git and Docker Desktop.
Verify:

```powershell
aws --version
terraform version
kubectl version --client
helm version
docker version
git --version
```

## 2. Configure AWS
Choose `ap-south-1` (Mumbai) for this project.

```powershell
aws configure
aws sts get-caller-identity
```

Use short-lived IAM Identity Center credentials in a real company; don't commit access keys.

## 3. Create GitHub repository
Create an empty repository called `quickcart-cloud-native`, clone it, copy this project into it, then:

```powershell
git add .
git commit -m "Initial quick commerce platform"
git branch -M main
git push -u origin main
```

## 4. Configure Terraform

```powershell
cd infra/terraform
copy terraform.tfvars.example terraform.tfvars
```

Set:

```hcl
region      = "ap-south-1"
project     = "quickcart"
db_name     = "quickcart"
db_user     = "quickcart"
db_password = "USE-A-STRONG-PASSWORD"
github_org  = "YOUR_GITHUB_USERNAME_OR_ORG"
github_repo = "quickcart-cloud-native"
```

Never commit `terraform.tfvars`.

## 5. Provision AWS

```powershell
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Type `yes`.

This creates VPC, public/private subnets, NAT, EKS, managed nodes, RDS PostgreSQL, ElastiCache Redis, ECR, S3 and the GitHub OIDC role.

## 6. Connect to EKS

```powershell
aws eks update-kubeconfig --region ap-south-1 --name quickcart-eks
kubectl get nodes
kubectl get pods -A
```

## 7. Build and push images manually once

```powershell
$ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
$REGION = "ap-south-1"
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

docker build -t quickcart-api services/api
docker tag quickcart-api:latest "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/quickcart/api:manual"
docker push "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/quickcart/api:manual"

docker build --build-arg VITE_API_URL=/api -t quickcart-web services/web
docker tag quickcart-web:latest "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/quickcart/web:manual"
docker push "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/quickcart/web:manual"
```

## 8. Install AWS Load Balancer Controller

AWS's current EKS guide uses the AWS Load Balancer Controller for ALB Ingress. Install its IAM policy/service account following the current AWS guide, then Helm install it. A typical Helm command after the service account exists is:

```powershell
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller `
  -n kube-system `
  --set clusterName=quickcart-eks `
  --set serviceAccount.create=false `
  --set serviceAccount.name=aws-load-balancer-controller
```

Verify:

```powershell
kubectl get deployment -n kube-system aws-load-balancer-controller
```

## 9. Deploy the app

Get endpoints:

```powershell
terraform output db_endpoint
terraform output redis_endpoint
terraform output ecr_api
terraform output ecr_web
```

Then deploy with Helm. Replace the placeholders:

```powershell
helm upgrade --install quickcart deploy/helm/quickcart `
  --namespace quickcart --create-namespace `
  --set api.image="$ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/quickcart/api" `
  --set api.tag="manual" `
  --set web.image="$ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/quickcart/web" `
  --set web.tag="manual" `
  --set api.databaseUrl="postgresql+psycopg://quickcart:YOUR_PASSWORD@DB_ENDPOINT:5432/quickcart" `
  --set api.redisUrl="redis://REDIS_ENDPOINT:6379/0"
```

Check:

```powershell
kubectl get pods -n quickcart
kubectl get ingress -n quickcart
```

## 10. GitHub Actions OIDC

Get the role ARN:

```powershell
terraform output github_actions_role_arn
```

In GitHub repository Settings → Secrets and variables → Actions, add:

```text
AWS_DEPLOY_ROLE_ARN = <role ARN>
AWS_ACCOUNT_ID      = <12 digit account ID>
```

The workflow already requests `id-token: write` and uses `aws-actions/configure-aws-credentials`.

Push:

```powershell
git add .
git commit -m "Enable AWS CI/CD"
git push origin main
```

Pipeline:

```text
GitHub → Test → Docker Build → Trivy → ECR → EKS → Helm
```

## 11. Monitoring

```powershell
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack `
  --namespace monitoring --create-namespace `
  -f observability/prometheus-values.yaml
```

Access Grafana locally:

```powershell
kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring
```

Open `http://localhost:3000`.

## 12. Production hardening

Before calling this genuinely production-ready, replace demo plaintext DB/Redis values with AWS Secrets Manager + External Secrets, remove AdministratorAccess from GitHub Actions, enable TLS/ACM, WAF, CloudFront, KMS, private data stores, image signing/SBOM, centralized logs, tracing, backups/restore tests, and a multi-region DR plan.

## 13. Destroy when finished

```powershell
cd infra/terraform
terraform destroy
```

EKS, NAT Gateway, RDS, Redis and load balancers can incur charges. Destroy the environment when you are not using it.
