output "cluster_name" { value=module.eks.cluster_name }
output "cluster_endpoint" { value=module.eks.cluster_endpoint }
output "ecr_api" { value=aws_ecr_repository.api.repository_url }
output "ecr_web" { value=aws_ecr_repository.web.repository_url }
output "db_endpoint" { value=aws_db_instance.postgres.address }
output "redis_endpoint" { value=aws_elasticache_replication_group.redis.primary_endpoint_address }
output "assets_bucket" { value=aws_s3_bucket.assets.bucket }
