variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "secret_arns" {
  type = list(string)
}

variable "log_group_name" {
  type = string
}
