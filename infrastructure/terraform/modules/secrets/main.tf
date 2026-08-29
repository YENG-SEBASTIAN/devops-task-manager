resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.name}/db-password"
  description             = "PostgreSQL master password"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id

  secret_string = jsonencode({
    username     = var.db_username
    password     = var.db_password
    dbname       = var.db_name
    host         = var.db_host
    port         = 5432
    database_url = "postgresql://${var.db_username}:${urlencode(var.db_password)}@${var.db_host}:5432/${var.db_name}"
  })
}

# ── Django Secret Key ───────────────────────────────────────

resource "aws_secretsmanager_secret" "django_secret_key" {
  name                    = "${var.name}/django-secret-key"
  description             = "Django SECRET_KEY"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "django_secret_key" {
  secret_id     = aws_secretsmanager_secret.django_secret_key.id
  secret_string = var.django_secret_key
}

# ── Redis Connection ────────────────────────────────────────

resource "aws_secretsmanager_secret" "redis" {
  name                    = "${var.name}/redis"
  description             = "Redis connection details"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "redis" {
  secret_id = aws_secretsmanager_secret.redis.id

  secret_string = jsonencode({
    host = var.redis_host
    port = 6379
  })
}