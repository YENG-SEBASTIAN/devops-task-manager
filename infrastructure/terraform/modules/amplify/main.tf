# ── Amplify IAM Role ────────────────────────────────────────

data "aws_iam_policy_document" "amplify_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["amplify.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "amplify" {
  name               = "${var.name}-amplify"
  assume_role_policy = data.aws_iam_policy_document.amplify_assume.json
}

resource "aws_iam_role_policy_attachment" "amplify" {
  role       = aws_iam_role.amplify.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess-Amplify"
}

# ── Amplify App ─────────────────────────────────────────────

resource "aws_amplify_app" "this" {
  name         = var.name
  repository   = var.github_repo
  access_token = var.github_token

  iam_service_role_arn = aws_iam_role.amplify.arn

  platform = "WEB"

  environment_variables = {
    NEXT_PUBLIC_API_URL = var.api_url
  }

  build_spec = <<-EOT
    version: 1
    applications:
      - appRoot: frontend
        frontend:
          phases:
            preBuild:
              commands:
                - npm ci
            build:
              commands:
                - npm run build
          artifacts:
            baseDirectory: out
            files:
              - '**/*'
          cache:
            paths:
              - node_modules/**/*
              - .next/cache/**/*
  EOT

  enable_branch_auto_build    = true
  enable_branch_auto_deletion = true

  custom_rule {
    source = "</^((?!\\/api\\/).)*$/>"
    status = "200"
    target = "/index.html"
  }

  custom_rule {
    source = "/api/<*>"
    status = "404"
    target = "/index.html"
  }

  tags = { Name = var.name }
}

# ── Main Branch ─────────────────────────────────────────────

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.this.id
  branch_name = "master"

  enable_auto_build = true

  environment_variables = {
    NEXT_PUBLIC_API_URL = var.api_url
  }

  tags = { Name = "${var.name}-main" }
}

# ── Staging Branch ──────────────────────────────────────────

resource "aws_amplify_branch" "staging" {
  app_id      = aws_amplify_app.this.id
  branch_name = "staging"

  enable_auto_build = true

  environment_variables = {
    NEXT_PUBLIC_API_URL = var.api_url
  }

  tags = { Name = "${var.name}-staging" }
}

# ── Domain ──────────────────────────────────────────────────

resource "aws_amplify_domain_association" "this" {
  count       = var.domain_name != "" ? 1 : 0
  app_id      = aws_amplify_app.this.id
  domain_name = var.domain_name

  sub_domain {
    branch_name = "master"
    prefix      = ""
  }

  sub_domain {
    branch_name = "staging"
    prefix      = "staging"
  }
}
