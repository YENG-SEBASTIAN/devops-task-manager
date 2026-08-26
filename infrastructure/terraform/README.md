# Terraform infrastructure

This directory holds the AWS infrastructure-as-code for the Task Manager.

Copy an environment variables file before planning changes:

```bash
cd infrastructure/terraform
cp environments/dev.tfvars.example environments/dev.tfvars
terraform init
terraform plan -var-file=environments/dev.tfvars
```

Remote state and locking should be configured before a shared environment is created. Do not commit `*.tfvars` files containing real values.
