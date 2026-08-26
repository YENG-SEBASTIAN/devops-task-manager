variable "name"           { type = string }
variable "region"         { type = string }
variable "secret_arns"    { type = list(string) }
variable "log_group_name" { type = string }

# ── Lambda IAM Role ─────────────────────────────────────────

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.name}-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda_permissions" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:${var.region}:*:*"]
  }

  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = var.secret_arns
  }

  statement {
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "ses:SendEmail",
      "ses:SendTemplatedEmail",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${var.name}-lambda"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_permissions.json
}

# ── SQS Queue (async processing) ────────────────────────────

resource "aws_sqs_queue" "notifications" {
  name                       = "${var.name}-notifications"
  message_retention_seconds  = 3456
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 30

  tags = { Name = "${var.name}-notifications" }
}

# ── Health Check Lambda ─────────────────────────────────────
# Pay-per-request: 1M free/month, then $0.20 per 1M requests
# Cold start: ~200ms, warm: ~5ms

data "archive_file" "health_check" {
  type        = "zip"
  output_path = "/tmp/health-check.zip"

  source {
    content  = file("${path.module}/functions/health_check.py")
    filename = "health_check.py"
  }
}

resource "aws_lambda_function" "health_check" {
  function_name = "${var.name}-health-check"
  filename      = data.archive_file.health_check.output_path
  source_code_hash = data.archive_file.health_check.output_base64sha256
  handler       = "health_check.handler"
  runtime       = "python3.12"
  timeout       = 10
  memory_size   = 128

  role = aws_iam_role.lambda.arn

  environment {
    variables = {
      DB_SECRET_ARN    = var.secret_arns[0]
      DJANGO_SECRET_ARN = var.secret_arns[1]
    }
  }

  tags = { Name = "${var.name}-health-check" }
}

# ── Notification Lambda (triggered by SQS) ──────────────────
# Processes email notifications, push alerts, etc.

data "archive_file" "notification" {
  type        = "zip"
  output_path = "/tmp/notification.zip"

  source {
    content  = file("${path.module}/functions/send_notification.py")
    filename = "send_notification.py"
  }
}

resource "aws_lambda_function" "notification" {
  function_name = "${var.name}-notification"
  filename      = data.archive_file.notification.output_path
  source_code_hash = data.archive_file.notification.output_base64sha256
  handler       = "send_notification.handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 128

  role = aws_iam_role.lambda.arn

  environment {
    variables = {
      DB_SECRET_ARN = var.secret_arns[0]
    }
  }

  tags = { Name = "${var.name}-notification" }
}

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = aws_sqs_queue.notifications.arn
  function_name    = aws_lambda_function.notification.arn
  batch_size       = 10
  enabled          = true
}

# ── Webhook Lambda (GitHub webhooks, Stripe, etc.) ──────────

data "archive_file" "webhook" {
  type        = "zip"
  output_path = "/tmp/webhook.zip"

  source {
    content  = file("${path.module}/functions/webhook_handler.py")
    filename = "webhook_handler.py"
  }
}

resource "aws_lambda_function" "webhook" {
  function_name = "${var.name}-webhook"
  filename      = data.archive_file.webhook.output_path
  source_code_hash = data.archive_file.webhook.output_base64sha256
  handler       = "webhook_handler.handler"
  runtime       = "python3.12"
  timeout       = 10
  memory_size   = 128

  role = aws_iam_role.lambda.arn

  environment {
    variables = {
      SQS_QUEUE_URL = aws_sqs_queue.notifications.id
      DB_SECRET_ARN = var.secret_arns[0]
    }
  }

  tags = { Name = "${var.name}-webhook" }
}

# ── Cleanup Lambda (scheduled, deletes old data) ─────────────
# Runs daily, pays only when it runs (~$0.0000167/execution)

data "archive_file" "cleanup" {
  type        = "zip"
  output_path = "/tmp/cleanup.zip"

  source {
    content  = file("${path.module}/functions/cleanup.py")
    filename = "cleanup.py"
  }
}

resource "aws_lambda_function" "cleanup" {
  function_name = "${var.name}-cleanup"
  filename      = data.archive_file.cleanup.output_path
  source_code_hash = data.archive_file.cleanup.output_base64sha256
  handler       = "cleanup.handler"
  runtime       = "python3.12"
  timeout       = 300
  memory_size   = 256

  role = aws_iam_role.lambda.arn

  environment {
    variables = {
      DB_SECRET_ARN = var.secret_arns[0]
    }
  }

  tags = { Name = "${var.name}-cleanup" }
}

resource "aws_cloudwatch_event_rule" "cleanup_schedule" {
  name                = "${var.name}-cleanup-schedule"
  description         = "Triggers cleanup Lambda daily at 3 AM UTC"
  schedule_expression = "cron(0 3 * * ? *)"
}

resource "aws_cloudwatch_event_target" "cleanup" {
  rule      = aws_cloudwatch_event_rule.cleanup_schedule.name
  target_id = "cleanup-lambda"
  arn       = aws_lambda_function.cleanup.arn
}

resource "aws_lambda_permission" "eventbridge_cleanup" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cleanup.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cleanup_schedule.arn
}

# ── Outputs ─────────────────────────────────────────────────

output "health_check_invoke_arn"    { value = aws_lambda_function.health_check.invoke_arn }
output "health_check_function_name" { value = aws_lambda_function.health_check.function_name }
output "notification_function_arn"  { value = aws_lambda_function.notification.arn }
output "webhook_function_arn"       { value = aws_lambda_function.webhook.arn }
output "cleanup_function_arn"       { value = aws_lambda_function.cleanup.arn }
output "sqs_queue_arn"              { value = aws_sqs_queue.notifications.arn }
output "sqs_queue_url"              { value = aws_sqs_queue.notifications.id }
output "lambda_role_arn"            { value = aws_iam_role.lambda.arn }
