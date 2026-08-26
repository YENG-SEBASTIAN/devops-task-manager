variable "name"                 { type = string }
variable "region"               { type = string }
variable "vpc_id"               { type = string }
variable "private_subnets"      { type = list(string) }
variable "backend_image"        { type = string }
variable "frontend_image"       { type = string }
variable "backend_sg_id"        { type = string }
variable "frontend_sg_id"       { type = string }
variable "backend_target_group"  { type = string }
variable "frontend_target_group" { type = string }
variable "execution_role_arn"   { type = string }
variable "task_role_arn"        { type = string }
variable "db_host"              { type = string }
variable "db_name"              { type = string }
variable "db_username"          { type = string }
variable "db_password"          { type = string }
variable "redis_host"           { type = string }
variable "django_secret_key"    { type = string }
variable "log_group_name"       { type = string }

# ── ECS Cluster ─────────────────────────────────────────────

resource "aws_ecs_cluster" "this" {
  name = var.name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = { Name = var.name }
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.name}"
  retention_in_days = 30
}

# ── Backend Task Definition ─────────────────────────────────

resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.name}-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([{
    name      = "backend"
    image     = var.backend_image
    essential = true

    portMappings = [{
      containerPort = 8000
      protocol      = "tcp"
    }]

    environment = [
      { name = "DJANGO_DEBUG",            value = "False" },
      { name = "ALLOWED_HOSTS",           value = "*" },
      { name = "CORS_ALLOWED_ORIGINS",    value = "http://${var.name}-alb-*.elb.amazonaws.com" },
      { name = "DATABASE_URL",            value = "postgresql://${var.db_username}:${var.db_password}@${var.db_host}:5432/${var.db_name}" },
      { name = "REDIS_URL",               value = "redis://${var.redis_host}:6379/0" },
      { name = "SECRET_KEY",              value = var.django_secret_key },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = var.log_group_name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "backend"
      }
    }

    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:8000/admin/ || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }])

  tags = { Name = "${var.name}-backend" }
}

# ── Frontend Task Definition ────────────────────────────────

resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.name}-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([{
    name      = "frontend"
    image     = var.frontend_image
    essential = true

    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]

    environment = [
      { name = "NEXT_PUBLIC_API_URL", value = "http://${var.name}-alb-*.elb.amazonaws.com/api" },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = var.log_group_name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "frontend"
      }
    }

    healthCheck = {
      command     = ["CMD-SHELL", "wget -qO- http://localhost:3000/ || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }])

  tags = { Name = "${var.name}-frontend" }
}

# ── Backend ECS Service ─────────────────────────────────────

resource "aws_ecs_service" "backend" {
  name            = "${var.name}-backend"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [var.backend_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.backend_target_group
    container_name   = "backend"
    container_port   = 8000
  }

  depends_on = [aws_ecs_task_definition.backend]
}

# ── Frontend ECS Service ────────────────────────────────────

resource "aws_ecs_service" "frontend" {
  name            = "${var.name}-frontend"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [var.frontend_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.frontend_target_group
    container_name   = "frontend"
    container_port   = 3000
  }

  depends_on = [aws_ecs_task_definition.frontend]
}

# ── Auto Scaling ────────────────────────────────────────────

resource "aws_appautoscaling_target" "backend" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.backend.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "backend_cpu" {
  name               = "${var.name}-backend-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.backend.resource_id
  scalable_dimension = aws_appautoscaling_target.backend.scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70
  }
}

resource "aws_appautoscaling_target" "frontend" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.frontend.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "frontend_cpu" {
  name               = "${var.name}-frontend-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.frontend.resource_id
  scalable_dimension = aws_appautoscaling_target.frontend.scalable_dimension
  service_namespace  = aws_appautoscaling_target.frontend.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 70
  }
}

output "cluster_name"   { value = aws_ecs_cluster.this.name }
output "cluster_arn"    { value = aws_ecs_cluster.this.arn }
output "backend_service"  { value = aws_ecs_service.backend.name }
output "frontend_service" { value = aws_ecs_service.frontend.name }
