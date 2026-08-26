output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = module.ecs.cluster_name
}

output "backend_repository_url" {
  description = "ECR backend repository URL."
  value       = module.ecr.backend_repository_url
}

output "frontend_repository_url" {
  description = "ECR frontend repository URL."
  value       = module.ecr.frontend_repository_url
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name."
  value       = module.alb.dns_name
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint."
  value       = module.rds.endpoint
}

output "redis_endpoint" {
  description = "ElastiCache Redis endpoint."
  value       = module.redis.endpoint
}

output "ecs_task_role_arn" {
  description = "ECS task role ARN (needed for GitHub Actions)."
  value       = module.iam.ecs_task_role_arn
}

output "ecs_execution_role_arn" {
  description = "ECS execution role ARN (needed for GitHub Actions)."
  value       = module.iam.ecs_execution_role_arn
}
