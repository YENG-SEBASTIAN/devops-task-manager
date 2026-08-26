variable "aws_region" {
  description = "AWS region where infrastructure will be provisioned."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name used to tag and name infrastructure resources."
  type        = string
  default     = "task-manager"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"
}

# ── Networking ──────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use."
  type        = number
  default     = 2
}

# ── Database ────────────────────────────────────────────────

variable "db_name" {
  description = "PostgreSQL database name."
  type        = string
  default     = "task_manager"
}

variable "db_username" {
  description = "PostgreSQL master username."
  type        = string
  default     = "task_manager"
  sensitive   = true
}

variable "db_password" {
  description = "PostgreSQL master password."
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

# ── Redis ───────────────────────────────────────────────────

variable "redis_node_type" {
  description = "ElastiCache Redis node type."
  type        = string
  default     = "cache.t3.micro"
}

# ── Docker Images ───────────────────────────────────────────

variable "backend_image" {
  description = "Backend Docker image URI (set by CI/CD)."
  type        = string
  default     = ""
}

# ── Secrets ─────────────────────────────────────────────────

variable "django_secret_key" {
  description = "Django secret key."
  type        = string
  sensitive   = true
}

# ── GitHub / Amplify ────────────────────────────────────────

variable "github_repo" {
  description = "GitHub repository URL (HTTPS)."
  type        = string
}

variable "github_token" {
  description = "GitHub personal access token for Amplify."
  type        = string
  sensitive   = true
}

# ── SSL ─────────────────────────────────────────────────────

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS on the ALB."
  type        = string
  default     = ""
}
