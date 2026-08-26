locals {
  name = "${var.project_name}-${var.environment}"
  azs  = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  backend_image  = var.backend_image != "" ? var.backend_image : "${aws_ecr_repository.backend.repository_url}:latest"
  frontend_image = var.frontend_image != "" ? var.frontend_image : "${aws_ecr_repository.frontend.repository_url}:latest"
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# ── VPC ─────────────────────────────────────────────────────

module "vpc" {
  source = "./modules/vpc"

  name       = local.name
  cidr       = var.vpc_cidr
  azs        = local.azs
  project_name = var.project_name
}

# ── ECR ─────────────────────────────────────────────────────

module "ecr" {
  source = "./modules/ecr"

  name = local.name
}

# ── IAM ─────────────────────────────────────────────────────

module "iam" {
  source = "./modules/iam"

  name               = local.name
  region             = var.aws_region
  backend_repo_arn   = module.ecr.backend_repository_arn
  frontend_repo_arn  = module.ecr.frontend_repository_arn
}

# ── ALB ─────────────────────────────────────────────────────

module "alb" {
  source = "./modules/alb"

  name            = local.name
  vpc_id          = module.vpc.vpc_id
  public_subnets  = module.vpc.public_subnets
  certificate_arn = var.certificate_arn
}

# ── Security Groups ─────────────────────────────────────────

resource "aws_security_group" "backend" {
  name_prefix = "${local.name}-backend-"
  vpc_id      = module.vpc.vpc_id
  description = "Backend ECS tasks security group"

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [module.alb.security_group_id]
    description     = "Allow traffic from ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = { Name = "${local.name}-backend" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "frontend" {
  name_prefix = "${local.name}-frontend-"
  vpc_id      = module.vpc.vpc_id
  description = "Frontend ECS tasks security group"

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [module.alb.security_group_id]
    description     = "Allow traffic from ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = { Name = "${local.name}-frontend" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "${local.name}-rds-"
  vpc_id      = module.vpc.vpc_id
  description = "RDS security group"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
    description     = "Allow PostgreSQL from backend"
  }

  tags = { Name = "${local.name}-rds" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "redis" {
  name_prefix = "${local.name}-redis-"
  vpc_id      = module.vpc.vpc_id
  description = "Redis security group"

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
    description     = "Allow Redis from backend"
  }

  tags = { Name = "${local.name}-redis" }

  lifecycle {
    create_before_destroy = true
  }
}

# ── RDS ─────────────────────────────────────────────────────

module "rds" {
  source = "./modules/rds"

  name               = local.name
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.rds.id]
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  instance_class     = var.db_instance_class
}

# ── Redis ───────────────────────────────────────────────────

module "redis" {
  source = "./modules/redis"

  name               = local.name
  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.redis.id]
  node_type          = var.redis_node_type
}

# ── ECS ─────────────────────────────────────────────────────

module "ecs" {
  source = "./modules/ecs"

  name                = local.name
  region              = var.aws_region
  vpc_id              = module.vpc.vpc_id
  private_subnets     = module.vpc.private_subnets
  backend_image       = local.backend_image
  frontend_image      = local.frontend_image
  backend_sg_id       = aws_security_group.backend.id
  frontend_sg_id      = aws_security_group.frontend.id
  backend_target_group = module.alb.backend_target_group_arn
  frontend_target_group = module.alb.frontend_target_group_arn
  execution_role_arn  = module.iam.ecs_execution_role_arn
  task_role_arn       = module.iam.ecs_task_role_arn
  db_host             = module.rds.endpoint
  db_name             = var.db_name
  db_username         = var.db_username
  db_password         = var.db_password
  redis_host          = module.redis.endpoint
  django_secret_key   = var.django_secret_key
  log_group_name      = module.cloudwatch.log_group_name
}

# ── CloudWatch ──────────────────────────────────────────────

module "cloudwatch" {
  source = "./modules/cloudwatch"

  name = local.name
}
