output "app_id"         { value = aws_amplify_app.this.id }
output "app_arn"        { value = aws_amplify_app.this.arn }
output "default_domain" { value = aws_amplify_app.this.default_domain }
output "amplify_url"    { value = "https://${aws_amplify_branch.main.branch_name}.${aws_amplify_app.this.default_domain}" }
