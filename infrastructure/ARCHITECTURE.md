# AWS Architecture

How the task-manager infrastructure runs on AWS and how user requests flow through the system.

---

## High-Level Overview

```
                            INTERNET
                               │
              ┌────────────────┼────────────────┐
              ▼                                 ▼
    ┌──────────────────┐              ┌──────────────────┐
    │   AWS Amplify    │              │   App Load       │
    │   (Frontend)     │              │   Balancer       │
    │                  │              │   (Backend API)  │
    │  Next.js static  │              │                  │
    │  assets served   │              │  HTTP :80        │
    │  from CDN edge   │              │  HTTPS :443      │
    └────────┬─────────┘              └────────┬─────────┘
             │                                 │
             │ HTTPS                    HTTPS  │
             │                                 ▼
             │                    ┌──────────────────────┐
             │                    │    Amazon ECS        │
             │                    │    (Fargate)         │
             │                    │                      │
             │                    │  ┌────────────────┐  │
             │                    │  │  Backend Task  │  │
             │                    │  │  Django REST   │  │
             │                    │  │  :8000         │  │
             │                    │  └───────┬────────┘  │
             │                    └──────────┼───────────┘
             │                               │
             │          ┌────────────────────┼────────────────────┐
             │          │                    │                    │
             │          ▼                    ▼                    ▼
             │  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
             │  │ Aurora       │   │ ElastiCache  │   │   Secrets    │
             │  │ PostgreSQL   │   │ Redis        │   │   Manager    │
             │  │ 16.6         │   │ 7.1          │   │              │
             │  │ (cluster)    │   │ (encrypted)  │   │  DB creds    │
             │  └──────────────┘   └──────────────┘   │  Django key  │
             │                                        │  Redis conn  │
             │                                        └──────────────┘
             │
     Frontend│makes API calls to backend
     SPA     │via NEXT_PUBLIC_API_URL
             │
             ▼
      ┌──────────────┐
      │   API Calls   │
      │   /api/*      │
      └──────────────┘
```

---

## Network Design (VPC)

```
                    VPC  10.0.0.0/16
         ┌──────────────────┴──────────────────┐
         │                                      │
  ───────┼──────────────────────  ──────────────┼──────────────────────
  AZ-a   │                                      │ AZ-b
  ───────┼──────────────────────  ─────── ──────┼──────────────────────
         │                                      │
   ┌─────┴─────┐                         ┌─────┴─────┐
   │  Public   │                         │  Public   │
   │  Subnet   │                         │  Subnet   │
   │ .0/24     │                         │ .1/24     │
   │           │                         │           │
   │  ┌─────┐  │                         │  ┌─────┐  │
   │  │NAT  │  │                         │  │NAT  │  │
   │  │GW   │  │                         │  │GW   │  │
   │  └─────┘  │                         │  └─────┘  │
   │           │                         │           │
   │  ALB      │                         │           │
   └─────┬─────┘                         └─────┬─────┘
         │                                      │
         │  0.0.0.0/0 ──► NAT GW ──► Internet  │
         │                                      │
   ┌─────┴─────┐                         ┌─────┴─────┐
   │  Private  │                         │  Private  │
   │  Subnet   │                         │  Subnet   │
   │ .100/24   │                         │ .101/24   │
   │           │                         │           │
   │  ECS      │                         │  ECS      │
   │  Tasks    │                         │  Tasks    │
   │           │                         │           │
   │  RDS      │                         │  RDS      │
   │  Redis    │                         │  Redis    │
   └───────────┘                         └───────────┘
```

| Subnet Type  | Purpose                        | Internet Access |
|-------------|-------------------------------|-----------------|
| Public      | ALB, NAT Gateways             | Direct via IGW  |
| Private     | ECS tasks, RDS, Redis         | Outbound via NAT |

---

## Request Flow

### 1. User loads the app

```
User browser (www.example.com)
  │
  │  DNS resolves to Amplify CDN edge
  ▼
AWS Amplify (edge)
  │
  │  Returns static Next.js build (HTML, JS, CSS)
  ▼
Browser renders SPA
```

### 2. User logs in or creates a task

```
Browser SPA
  │
  │  POST /api/auth/login  { email, password }
  │  (or any /api/* request)
  │
  │  DNS resolves to ALB DNS name
  ▼
Application Load Balancer (port 80/443)
  │
  │  Routes to target group (IP targets)
  ▼
ECS Fargate Task (private subnet)
  │
  │  Django REST Framework handles request
  │  JWT auth validated
  │  Query hits PostgreSQL
  │  Cache check hits Redis
  ▼
Response returned to browser
```

### 3. Background processing

```
Django backend
  │
  │  Enqueues notification event to SQS
  ▼
Amazon SQS (notifications queue)
  │
  │  Event source mapping triggers Lambda
  ▼
Notification Lambda
  │
  │  Reads DB credentials from Secrets Manager
  │  Sends email via SES
  ▼
Email delivered to user
```

### 4. Scheduled cleanup

```
Amazon EventBridge (cron: daily 3 AM UTC)
  │
  │  Triggers cleanup Lambda
  ▼
Cleanup Lambda
  │
  │  Connects to RDS via Secrets Manager
  │  Deletes expired tokens, old sessions
  ▼
CloudWatch Logs
```

---

## Component Breakdown

### Frontend — AWS Amplify

| Property | Value |
|----------|-------|
| Platform | Next.js (static export) |
| Build | `npm ci && npm run build` |
| Auto-deploy | Push to `master` triggers build |
| Preview | All branches get PR preview URLs |
| Custom domain | Optional (configurable) |
| Env var | `NEXT_PUBLIC_API_URL` pointing to backend ALB |

Amplify hosts the static frontend build. No servers to manage. CDN is built-in.

### Backend — ECS Fargate

| Property | Value |
|----------|-------|
| Cluster | `task-manager-dev` |
| Launch type | Fargate (serverless containers) |
| Task size | 256 CPU / 512 MB RAM |
| Tasks | 2 (min) — 4 (max) auto-scaling |
| Port | 8000 |
| Health check | `curl -f http://localhost:8000/admin/` |
| Image source | ECR (`task-manager-backend`) |
| Secrets | Pulled from Secrets Manager at task start |

Auto-scaling triggers at 70% average CPU utilization across tasks.

### Load Balancer — ALB

| Property | Value |
|----------|-------|
| Type | Application Load Balancer |
| Scheme | Internet-facing |
| Listeners | HTTP :80 (or HTTPS :443 if cert provided) |
| Target group | Backend tasks (IP mode, port 8000) |
| Health check | `/admin/` (200 or 302 = healthy) |
| Security group | Allows 80/443 inbound from anywhere |

SSL termination happens at the ALB when a certificate ARN is provided. Without a cert, plain HTTP is used (dev mode).

### Database — Aurora PostgreSQL

| Property | Value |
|----------|-------|
| Engine | Aurora PostgreSQL 16.6 |
| Instance | `db.t3.micro` (1 instance) |
| Storage | Encrypted at rest |
| Subnet group | Private subnets only |
| Access | Only from backend security group (port 5432) |
| Password | Rotated via Secrets Manager |

Aurora PostgreSQL provides automatic failover, point-in-time recovery, and encryption at rest. The single-instance dev config keeps costs low.

### Cache — ElastiCache Redis

| Property | Value |
|----------|-------|
| Engine | Redis 7.1 |
| Node type | `cache.t3.micro` |
| Encryption | At rest + in transit |
| Subnet group | Private subnets only |
| Access | Only from backend security group (port 6379) |

Used for session storage, JWT blacklist, and API response caching.

### Secrets — Secrets Manager

| Secret | Contents |
|--------|----------|
| `task-manager-dev/db-password` | username, password, dbname, host, port |
| `task-manager-dev/django-secret-key` | Django `SECRET_KEY` value |
| `task-manager-dev/redis` | host, port |

ECS task role has `secretsmanager:GetSecretValue` permission. Secrets are injected as environment variables at container start, never stored in images or code.

### Async Processing — Lambda + SQS + EventBridge

| Function | Trigger | Purpose |
|----------|---------|---------|
| `health-check` | Manual / API Gateway | Validates DB and Redis connectivity |
| `notification` | SQS queue (event source mapping) | Sends emails via SES when tasks change |
| `webhook` | API Gateway (optional) | Processes GitHub webhooks or Stripe events |
| `cleanup` | EventBridge cron (daily 3 AM UTC) | Deletes expired tokens and old sessions |

All Lambda functions share a single IAM role with Secrets Manager, SQS, SES, and CloudWatch Logs permissions.

### Monitoring — CloudWatch

| Resource | Purpose |
|----------|---------|
| Log group `/ecs/task-manager-dev` | All ECS task logs (30-day retention) |
| Alarm: backend CPU > 80% | Alerts when backend is CPU-bound |
| Alarm: backend memory > 85% | Alerts on memory pressure |
| Alarm: ALB 5xx errors > 10 | Alerts on server errors |
| Dashboard | Visual overview of CPU, memory, request count |

---

## Security Model

```
                         ┌──────────────────────────┐
                         │     Security Layers       │
                         └──────────────────────────┘

Layer 1:  Network        VPC isolates all resources
                         Public subnets: only ALB + NAT GW
                         Private subnets: ECS, RDS, Redis

Layer 2:  Security Groups ALB SG:     80/443 from 0.0.0.0/0
                         Backend SG: 8000 from ALB only
                         RDS SG:     5432 from Backend only
                         Redis SG:   6379 from Backend only

Layer 3:  IAM            ECS Execution: pull images, read secrets
                         ECS Task:      app permissions (secrets, logs)
                         GitHub OIDC:   push images, update ECS service
                         Lambda:        secrets, SQS, SES, logs

Layer 4:  Encryption     RDS:    storage encrypted (AES-256)
                         Redis:  at-rest + in-transit encryption
                         Secrets: encrypted with AWS-managed key
                         ALB:    TLS 1.3 (when certificate provided)

Layer 5:  Secrets        Never in code, never in Docker images
                         Injected from Secrets Manager at runtime
                         Least-privilege per component
```

---

## CI/CD Pipeline

```
  Developer pushes to master
  │
  ▼
GitHub Actions (deploy.yml)
  │
  ├─► Test job
  │     pytest (backend)
  │     tsc --noEmit + eslint (frontend)
  │
  ├─► Build & Push backend
  │     docker build backend/
  │     docker tag → ECR
  │     docker push to ECR
  │
  ├─► Deploy backend to ECS
  │     Update task definition with new image
  │     Rolling deploy (0 new tasks, drain old)
  │
  └─► Deploy frontend to Amplify
        Trigger Amplify build on master
        Amplify builds Next.js and deploys to CDN

  Total deploy time: ~3-5 minutes
```

---

## Cost Estimate (Dev Traffic)

| Service | Monthly Cost |
|---------|-------------|
| ECS Fargate (2 tasks, 256/512) | ~$30 |
| ALB | ~$16 |
| Aurora PostgreSQL (`db.t3.micro`) | ~$13 |
| ElastiCache Redis (`cache.t3.micro`) | ~$12 |
| NAT Gateway (x2) | ~$65 |
| Secrets Manager (3 secrets) | ~$1 |
| CloudWatch (logs + alarms) | ~$5 |
| Lambda (light usage) | ~$0.50 |
| Amplify (free tier) | $0 |
| **Total** | **~$140/month** |

> NAT Gateways are the largest cost. For a dev-only environment, a single NAT Gateway could reduce this to ~$80/month. The Terraform config creates one per AZ for production HA.

---

## Terraform Module Structure

```
infrastructure/terraform/
├── main.tf              # Root module — wires everything together
├── variables.tf         # All input variables
├── outputs.tf           # All outputs (DNS, ARNs, endpoints)
├── versions.tf          # Provider versions + S3 backend for state
├── environments/
│   └── dev.tfvars.example
└── modules/
    ├── vpc/             # VPC, subnets, NAT, routes
    ├── ecr/             # Backend + frontend image repos
    ├── alb/             # Load balancer, target groups, listeners
    ├── ecs/             # Fargate cluster, task def, service, autoscaling
    ├── rds/             # Aurora PostgreSQL cluster + instance
    ├── redis/           # ElastiCache Redis replication group
    ├── iam/             # ECS roles, GitHub OIDC, task permissions
    ├── secrets/         # Secrets Manager entries
    ├── amplify/         # Amplify app + IAM + branches
    ├── lambda/          # 4 Lambda functions + SQS + EventBridge
    └── cloudwatch/      # Log groups, alarms, dashboard

Each module contains:
    main.tf       # Resources
    variables.tf  # Input variables
    outputs.tf    # Output values
```

---

## Deployment

### Prerequisites

```bash
# 1. Install AWS CLI + configure credentials
aws configure

# 2. Create Terraform state backend
aws s3 mb s3://task-manager-terraform-state --region us-east-1
aws dynamodb create-table \
  --table-name task-manager-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1

# 3. Create tfvars file
cp environments/dev.tfvars.example environments/dev.tfvars
# Fill in: db_password, django_secret_key, github_token
```

### Deploy

```bash
cd infrastructure/terraform

terraform init
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
```

### Outputs

After apply, Terraform outputs:

| Output | Description |
|--------|-------------|
| `amplify_url` | Frontend URL (open in browser) |
| `alb_dns_name` | Backend API endpoint |
| `github_actions_role_arn` | Set as `AWS_ROLE_ARN` in GitHub secrets |
| `amplify_app_id` | Set as `AMPLIFY_APP_ID` in GitHub secrets |
