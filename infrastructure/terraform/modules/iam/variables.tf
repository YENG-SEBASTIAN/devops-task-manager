variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "backend_repo_arn" {
  type = string
}

variable "secret_arns" {
  type = list(string)
}

variable "amplify_app_arn" {
  type = string
}

variable "lambda_role_arn" {
  type = string
}

variable "sqs_queue_arn" {
  type = string
}
