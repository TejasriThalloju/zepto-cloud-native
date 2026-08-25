data "aws_availability_zones" "available" { state = "available" }

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
  public_subnets  = ["10.20.1.0/24","10.20.2.0/24","10.20.3.0/24"]
  private_subnets = ["10.20.11.0/24","10.20.12.0/24","10.20.13.0/24"]
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"
  name = "${var.project}-vpc"
  cidr = var.vpc_cidr
  azs = local.azs
  public_subnets = local.public_subnets
  private_subnets = local.private_subnets
  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"
  name = "${var.project}-eks"
  kubernetes_version = "1.33"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  endpoint_public_access = true
  authentication_mode = "API_AND_CONFIG_MAP"
  access_entries = {
    github_actions = {
      principal_arn = aws_iam_role.github_actions.arn
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = { type = "cluster" }
        }
      }
    }
  }

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.large"]
      min_size = 2
      max_size = 6
      desired_size = 3
      capacity_type = "ON_DEMAND"
    }
  }
}

resource "aws_security_group" "db" {
  name   = "${var.project}-db"
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }
  egress { from_port=0 to_port=0 protocol="-1" cidr_blocks=["0.0.0.0/0"] }
}

resource "aws_db_subnet_group" "db" {
  name = "${var.project}-db-subnets"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_db_instance" "postgres" {
  identifier = "${var.project}-postgres"
  engine = "postgres"
  engine_version = "17"
  instance_class = "db.t4g.micro"
  allocated_storage = 30
  storage_type = "gp3"
  db_name = var.db_name
  username = var.db_user
  password = var.db_password
  port = 5432
  db_subnet_group_name = aws_db_subnet_group.db.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible = false
  skip_final_snapshot = true
  backup_retention_period = 7
}

resource "aws_security_group" "redis" {
  name   = "${var.project}-redis"
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port=6379 to_port=6379 protocol="tcp"
    security_groups=[module.eks.node_security_group_id]
  }
  egress { from_port=0 to_port=0 protocol="-1" cidr_blocks=["0.0.0.0/0"] }
}

resource "aws_elasticache_subnet_group" "redis" {
  name = "${var.project}-redis"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.project}-redis"
  description = "QuickCart cache"
  engine = "redis"
  node_type = "cache.t4g.micro"
  num_cache_clusters = 1
  subnet_group_name = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]
  automatic_failover_enabled = false
}

resource "aws_s3_bucket" "assets" {
  bucket_prefix = "${var.project}-assets-"
  force_destroy = true
}

resource "aws_ecr_repository" "api" {
  name = "${var.project}/api"
  image_scanning_configuration { scan_on_push = true }
}
resource "aws_ecr_repository" "web" {
  name = "${var.project}/web"
  image_scanning_configuration { scan_on_push = true }
}
