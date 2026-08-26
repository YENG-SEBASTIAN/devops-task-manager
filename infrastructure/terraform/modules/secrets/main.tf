variable "name"         { type = string }
variable "db_name"      { type = string }
variable "db_username"  { type = string }
variable "db_password"  { type = string }
variable "db_host"      { type = string }
variable "redis_host"   { type = string }
variable "django_secret_key" { type = string }

# ── Database Secrets ────────────────────────────────────────

resource "aws_secretsmanager_secret" "db_password" {
  name        = "${var.name}/db-password"
  description = "PostgreSQL master password"
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    dbname   = var.db_name
    host     = var.db_host
    port     = 5432
  })
}

# ── Django Secret Key ───────────────────────────────────────

resource "aws_secretsmanager_secret" "django_secret_key" {
  name        = "${var.name}/django-secret-key"
  description = "Django SECRET_KEY"
}

resource "aws_secretsmanager_secret_version" "django_secret_key" {
  secret_id     = aws_secretsmanager_secret.django_secret_key.id
  secret_string = var.django_secret_key
}

# ── Redis Connection ────────────────────────────────────────

resource "aws_secretsmanager_secret" "redis" {
  name        = "${var.name}/redis"
  description = "Redis connection details"
}

resource "aws_secretsmanager_secret_version" "redis" {
  secret_id = aws_secretsmanager_secret.redis.id
  secret_string = jsonencode({
    host = var.redis_host
    port = 6379
  })
}

output "db_secret_arn"         { value = aws_secretsmanager_secret.db_password.arn }
output "django_secret_arn"     { value = aws_secretsmanager_secret.django_secret_key.arn }
output "redis_secret_arn"      { value = aws_secretsmanager_secret.redis.arn }
output "db_secret_name"        { value = aws_secretsmanager_secret.db_password.name }
output "django_secret_name"    { value = aws_secretsmanager_secret.django_secret_key.name }
output "redis_secret_name"     { value = aws_secretsmanager_secret.redis.name }
