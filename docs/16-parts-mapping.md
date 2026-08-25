# 16-part blueprint → implementation

1. Project initialization → AWS account/IAM + Terraform.
2. GitHub → `.github/workflows`, branch protection should be configured in GitHub.
3. Terraform → `infra/terraform`.
4. Docker → `services/*/Dockerfile`.
5. CI/CD → `.github/workflows/ci-cd.yml`.
6. EKS → Terraform EKS module + Helm.
7. Helm → `deploy/helm/quickcart`.
8. Exposure/load balancing → ingress-nginx + Kubernetes Ingress.
9. Secrets → demo currently uses Helm values; production should use Secrets Manager + External Secrets.
10. Monitoring → `observability/prometheus-values.yaml`.
11. Logging → install Fluent Bit + OpenSearch/Kibana in production.
12. Security → NetworkPolicy, RBAC, Trivy, private data stores, least privilege.
13. Backup/DR → RDS automated backups; add AWS Backup and cross-region strategy.
14. Autoscaling/HA → HPA, PDB, multi-AZ node groups.
15. Blue/green/canary → add Argo Rollouts and switch Helm deployment strategy.
16. Tracing → add OpenTelemetry SDK/collector and Jaeger/Tempo; the API is the place to instrument spans.

## Recommended production topology

CloudFront/WAF
      |
      v
ALB/NLB
      |
EKS private subnets
  |       |       |
Web     API    workers
  |       |       |
  +-------+-------+
          |
       RDS/Redis
     private subnets

For a real commercial system, separate catalog, cart, order, payment, inventory,
notification and delivery services, use an event bus/queue, and introduce
idempotency/outbox patterns.
