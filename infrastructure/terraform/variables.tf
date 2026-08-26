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
