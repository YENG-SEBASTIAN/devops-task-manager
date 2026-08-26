variable "name" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "github_token" {
  type      = string
  sensitive = true
}

variable "api_url" {
  type = string
}

variable "backend_repo_arn" {
  type = string
}

variable "domain_name" {
  type    = string
  default = ""
}
