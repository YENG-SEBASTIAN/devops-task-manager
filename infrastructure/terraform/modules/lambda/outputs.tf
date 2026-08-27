output "health_check_invoke_arn" { value = aws_lambda_function.health_check.invoke_arn }
output "health_check_function_name" { value = aws_lambda_function.health_check.function_name }
output "notification_function_arn" { value = aws_lambda_function.notification.arn }
output "webhook_function_arn" { value = aws_lambda_function.webhook.arn }
output "cleanup_function_arn" { value = aws_lambda_function.cleanup.arn }
output "sqs_queue_arn" { value = aws_sqs_queue.notifications.arn }
output "sqs_queue_url" { value = aws_sqs_queue.notifications.id }
output "lambda_role_arn" { value = aws_iam_role.lambda.arn }
