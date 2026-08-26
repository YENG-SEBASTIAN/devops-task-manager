output "db_secret_arn"     { value = aws_secretsmanager_secret.db_password.arn }
output "django_secret_arn" { value = aws_secretsmanager_secret.django_secret_key.arn }
output "redis_secret_arn"  { value = aws_secretsmanager_secret.redis.arn }
output "db_secret_name"    { value = aws_secretsmanager_secret.db_password.name }
output "django_secret_name"{ value = aws_secretsmanager_secret.django_secret_key.name }
output "redis_secret_name" { value = aws_secretsmanager_secret.redis.name }
