variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "backend_image" {
  type = string
}

variable "backend_sg_id" {
  type = string
}

variable "backend_target_group" {
  type = string
}

variable "execution_role_arn" {
  type = string
}

variable "task_role_arn" {
  type = string
}

variable "db_secret_arn" {
  type = string
}

variable "django_secret_arn" {
  type = string
}

variable "redis_secret_arn" {
  type = string
}

variable "log_group_name" {
  type = string
}
