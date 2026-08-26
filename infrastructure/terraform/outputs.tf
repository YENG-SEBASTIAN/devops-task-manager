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

output "alb_dns_name" {
  description = "Application Load Balancer DNS name (backend API)."
  value       = module.alb.dns_name
}

output "api_url" {
  description = "Backend API URL."
  value       = local.api_url
}

output "amplify_app_id" {
  description = "Amplify app ID."
  value       = module.amplify.app_id
}

output "amplify_url" {
  description = "Amplify frontend URL."
  value       = module.amplify.amplify_url
}

output "amplify_default_domain" {
  description = "Amplify default domain."
  value       = module.amplify.default_domain
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint."
  value       = module.rds.endpoint
}

output "redis_endpoint" {
  description = "ElastiCache Redis endpoint."
  value       = module.redis.endpoint
}

output "secrets_manager_arns" {
  description = "Secrets Manager secret ARNs."
  value = {
    db_password     = module.secrets.db_secret_arn
    django_secret   = module.secrets.django_secret_arn
    redis           = module.secrets.redis_secret_arn
  }
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions."
  value       = module.iam.github_actions_role_arn
}
