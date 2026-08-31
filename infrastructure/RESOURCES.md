# AWS Resource Inventory & Interactions

An exhaustive catalog of every AWS resource provisioned by the Terraform configuration in
`infrastructure/terraform`, plus how each piece of infrastructure interacts with the others.

- **Region:** `eu-west-2` (London)
- **Naming prefix:** `task-manager-dev` (`${project_name}-${environment}`)
- **Account:** `766696030279`
- **Source of truth:** `infrastructure/terraform/main.tf` + `modules/*`

> Note: `infrastructure/ARCHITECTURE.md` covers the higher-level request flow and design
> narrative. This document is the ground-truth **resource inventory** and **dependency graph**
> derived directly from the Terraform code.

---

## 1. Resource Inventory by Module

### `modules/vpc` — Networking

| Resource | Count | Name (example) | Notes |
|----------|-------|----------------|-------|
| `aws_vpc` | 1 | `task-manager-dev` | CIDR `10.0.0.0/16`, DNS hostnames + support enabled |
| `aws_subnet` (public) | per-AZ (2) | `task-manager-dev-public-<az>` | `map_public_ip_on_launch = true` |
| `aws_subnet` (private) | per-AZ (2) | `task-manager-dev-private-<az>` | No public IP |
| `aws_internet_gateway` | 1 | `task-manager-dev-igw` | Public internet egress |
| `aws_eip` | per-AZ (2) | `task-manager-dev-nat-eip-<az>` | Elastic IPs for NAT |
| `aws_nat_gateway` | per-AZ (2) | `task-manager-dev-nat-<az>` | Outbound for private subnets |
| `aws_route_table` (public) | 1 | `task-manager-dev-public-rt` | `0.0.0.0/0 → IGW` |
| `aws_route_table` (private) | per-AZ (2) | `task-manager-dev-private-rt-<az>` | `0.0.0.0/0 → NAT GW` |
| `aws_route` + associations | — | — | Wire routes to subnets |

### `modules/ecr` — Container Registry

| Resource | Count | Name | Notes |
|----------|-------|------|-------|
| `aws_ecr_repository` | 1 | `task-manager-dev-backend` | Scan on push, MUTABLE tags |
| `aws_ecr_repository` | 1 | `task-manager-dev-frontend` | Scan on push, MUTABLE tags |
| `aws_ecr_lifecycle_policy` | 2 | — | Keep last 30 images per repo |

### `modules/alb` — Load Balancer (backend API)

| Resource | Count | Name | Notes |
|----------|-------|------|-------|
| `aws_security_group` | 1 | `task-manager-dev-alb` | Inbound 80/443 from `0.0.0.0/0` |
| `aws_lb` | 1 | `task-manager-dev` | Internet-facing, ALB type |
| `aws_lb_target_group` | 1 | `task-manager-dev-backend` | IP mode, port 8000, health check `/admin/` |
| `aws_lb_listener` (https) | 0 or 1 | — | Only if `certificate_arn` set |
| `aws_lb_listener` (http) | 0 or 1 | — | Only if no cert (active by default: HTTP :80) |

### `modules/ecs` — Backend compute

| Resource | Count | Name | Notes |
|----------|-------|------|-------|
| `aws_ecs_cluster` | 1 | `task-manager-dev` | Container Insights enabled |
| `aws_ecs_task_definition` | 1 | `task-manager-dev-backend` | Fargate, awsvpc, 256 CPU / 512MB |
| `aws_ecs_service` | 1 | `task-manager-dev-backend` | Desired 2, health check `/admin/` |
| `aws_appautoscaling_target` | 1 | — | Min 2, max 4 |
| `aws_appautoscaling_policy` | 1 | `task-manager-dev-backend-cpu` | CPU 70% target tracking |

### `modules/rds` — PostgreSQL database (RDS, not Aurora)

| Resource | Count | Name | Notes |
|----------|-------|------|-------|
| `aws_db_subnet_group` | 1 | `task-manager-dev-db` | Private subnets |
| `aws_db_instance` | 1 | `task-manager-dev-db` | Postgres 16.14, gp3, encrypted, not public |

### `modules/redis` — ElastiCache Redis

| Resource | Count | Name | Notes |
|----------|-------|------|-------|
| `aws_elasticache_subnet_group` | 1 | `task-manager-dev-redis` | Private subnets |
| `aws_elasticache_replication_group` | 1 | `task-manager-dev-redis` | Redis 7.1, 1 shard, 6379, encrypted at rest + in transit |

### `modules/secrets` — AWS Secrets Manager

| Resource | Count | Name | Contents |
|----------|-------|------|----------|
| `aws_secretsmanager_secret` + version | 2 | `task-manager-dev/db-password` | username, password, dbname, host, port, `database_url` |
| `aws_secretsmanager_secret` + version | 2 | `task-manager-dev/django-secret-key` | Django `SECRET_KEY` |
| `aws_secretsmanager_secret` + version | 2 | `task-manager-dev/redis` | host, port |

### `modules/iam` — Identity & Roles

| Resource | Name | Downloads image | Purpose |
|----------|------|-----------------|---------|
| `aws_iam_role` | `task-manager-dev-ecs-execution` | — | Pull images, read secrets, write logs |
| `aws_iam_role` | `task-manager-dev-ecs-task` | — | In-app secret + log access |
| `aws_iam_openid_connect_provider` | `task-manager-dev-github-oidc` | — | GitHub Actions OIDC federated trust |
| `aws_iam_role` | `task-manager-dev-github-actions` | — | CI/CD deploy powers (ECR, ECS, Amplify, Secrets, Lambda) |
| (in `amplify` module) `aws_iam_role` | `task-manager-dev-amplify` | — | Amplify assumes to build/deploy |
| (in `lambda` module) `aws_iam_role` | `task-manager-dev-lambda` | — | Lambda runtime permissions |

### `modules/amplify` — Frontend hosting

| Resource | Count | Name | Notes |
|----------|-------|------|-------|
| `aws_iam_role` + policy | 1 | `task-manager-dev-amplify` | Administrators policy for Amplify |
| `aws_amplify_app` | 1 | `task-manager-dev` | GitHub repo, env `NEXT_PUBLIC_API_URL`, build spec, custom rules |
| `aws_amplify_branch` | 2 | `master`, `staging` | Auto-build enabled |
| `aws_amplify_domain_association` | 0 (unless `domain_name` set) | — | Optional custom domain |

### `modules/lambda` — Serverless functions

| Resource | Count | Name | Trigger |
|----------|-------|------|---------|
| `aws_iam_role` | 1 | `task-manager-dev-lambda` | — |
| `aws_sqs_queue` | 1 | `task-manager-dev-notifications` | Async queue |
| `aws_lambda_function` | 1 | `task-manager-dev-health-check` | Manual / API Gateway |
| `aws_lambda_function` | 1 | `task-manager-dev-notification` | SQS event source mapping |
| `aws_lambda_function` | 1 | `task-manager-dev-webhook` | API Gateway (optional) |
| `aws_lambda_function` | 1 | `task-manager-dev-cleanup` | EventBridge cron (03:00 UTC daily) |
| `aws_lambda_event_source_mapping` | 1 | — | SQS → notification Lambda |
| `aws_cloudwatch_event_rule` + target | 1 | `task-manager-dev-cleanup-schedule` | Cron → cleanup Lambda |
| `aws_lambda_permission` | 1 | — | Allow EventBridge to invoke cleanup |

### `modules/cloudwatch` — Monitoring

| Resource | Count | Name | Notes |
|----------|-------|------|-------|
| `aws_cloudwatch_log_group` | 1 | `/ecs/task-manager-dev` | 30-day retention |
| `aws_cloudwatch_metric_alarm` | 2 | `task-manager-dev-backend-cpu-high` (80%), `-backend-memory-high` (85%) | ECS CPU/Memory |
| `aws_cloudwatch_metric_alarm` | 1 | `task-manager-dev-alb-5xx-errors` | ALB 5xx rate > 10 |
| `aws_cloudwatch_dashboard` | 1 | `task-manager-dev` | CPU, memory, request count widgets |

### Root `main.tf` (extra resources)

| Resource | Name | Notes |
|----------|------|-------|
| `aws_security_group.backend` | `task-manager-dev-backend` | Inbound 8000 from ALB SG only |
| `aws_security_group.rds` | `task-manager-dev-rds` | Inbound 5432 from backend SG only |
| `aws_security_group.redis` | `task-manager-dev-redis` | Inbound 6379 from backend SG only |

---

## 2. Interaction Map — Who Talks to Whom

```
                              ┌─────────────────────────────┐
                              │      GitHub (repo)          │
                              └──────────┬──────────────────┘
                                         │ OIDC (token.actions.githubusercontent.com)
                                         ▼
                              ┌─────────────────────────────┐
                              │  IAM role: github-actions    │ ── ECR push, ECS update,
                              │  (federated via OIDC)        │    Secrets read, Amplify:*,
                              └─────────────────────────────┘    Lambda updates
                                 │ CI/CD (deploy.yml)
                    ┌────────────┼──────────────┬─────────────┐
                    ▼            ▼              ▼             ▼
         ┌───────────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐
         │ ECR (images)  │  │   ECS    │  │ Amplify  │  │ Secrets  │
         └───────┬───────┘  └────┬─────┘  └────┬─────┘  │ Manager  │
                 │               │             │        │          │
                 │ push          │pull image   │ build   │ reads    │
                 ▼               ▼             ▼ from GH │          │
         ┌───────────────┐  ┌──────────┐  ┌──────────┐  │          │
         │  Frontend     │  │  ALB     │  │ Frontend │  └────┬─────┘
         │  ECR repo     │  │ (port 80)│  │ (static  │       │
         └───────────────┘  └────┬─────┘  │  build)  │       │
                                 │         └──────────┘       │
                                 │ HTTPS browser /api/*       │
                                 ▼                             │
                        ┌────────────────┐                     │
                        │   ECS cluster  │                     │
                        │  (Fargate)     │                     │
                        │  backend task  │                     │
                        │  Django :8000  │◄────────────────────┘
                        └───────┬────────┘   reads secrets from
                                │            Secrets Manager
         ┌──────────┬───────────┴───────────┬──────────┬───────────┐
         ▼          ▼                       ▼          ▼           ▼
   ┌─────────┐ ┌─────────┐           ┌──────────┐ ┌──────────┐ ┌──────────┐
   │   RDS   │ │ Redis   │           │ CloudWatch│ │   SQS    │ │   SES    │
   │ Postgres│ │ ElastiCh.│          │ logs/     │ │ notific. │ │ (email)  │
   │  :5432  │ │  :6379   │          │ alarms/   │ │ queue    │ │          │
   └─────────┘ └─────────┘           └──────────┘ │   ▲      │ └──────────┘
      │             │                             │   │      │       ▲
      └───────┬─────┘                             │  event    │      │
              │ private subnets only              │ source    │      │
              ▼                                   └───┼────────┴──────┘
     (All 4 Lambda functions read RDS via Secrets)   │
              │                                      │
              └──────────────►  Lambda (4 fns) ◄─────┘
                                       │
                    ┌──────────────────┼──────────────────┐
                    │                  │                  │
                    ▼                  ▼                  ▼
               EventBridge       SQS -> notification   CloudWatch Logs
               cron -> cleanup   Lambda -> SES email   (Lambda logs)
```

### Key edges (direction of dependency)

| From | To | Mechanism / Port | Purpose |
|------|----|------------------|---------|
| GitHub Actions → ECR | `ecr:BatchGetImage` etc. | OIDC + IAM role | Push backend image |
| GitHub Actions → ECS | `ecs:UpdateService`, `RunTask` | IAM | Deploy / run migrations |
| GitHub Actions → Amplify | `amplify:*` | IAM | Start frontend deploy |
| GitHub Actions → Secrets | `secretsmanager:GetSecretValue` | IAM | (limited scope) |
| GitHub Actions → Lambda | `lambda:Update*` | IAM | Update function code |
| ALB → ECS backend | ALB listener → target group (IP, port 8000) | TCP | Route `/api/*` to Django |
| ALB SG → backend SG | Security group reference (port 8000) | SG | Only ALB may reach backend |
| Backend ECS → RDS | `aws_security_group.rds` ingress from backend SG (5432) | SG | Postgres access |
| Backend ECS → Redis | `aws_security_group.redis` ingress from backend SG (6379) | SG | Cache / sessions |
| Backend ECS → Secrets | ECS task role `GetSecretValue` | IAM | Inject `SECRET_KEY`, `DATABASE_URL` |
| Backend ECS → ECR | ECS execution role pull image | IAM | Start containers |
| Backend ECS → CloudWatch | `awslogs` log driver | Log stream | Container logs |
| ECS autoscaling | CloudWatch metric (CPU) | Metric | Scale 2 ↔ 4 |
| Amplify → GitHub | clone repo (HTTPS token) | Build | Get frontend source |
| Amplify → env | `NEXT_PUBLIC_API_URL` = ALB URL | Build env | Frontend API target |
| Amplify → ECS-Frontend | N/A (frontend not on ECS) | — | Frontend served by Amplify CDN |
| Browser → ALB | HTTP :80 (no cert) / HTTPS :443 | Internet | Backend API calls |
| Browser → Amplify | HTTPS | Internet/CDN | Serve static frontend |
| Lambda → Secrets | Lambda role `GetSecretValue` | IAM | DB/connection creds |
| Lambda → SQS | `sqs:SendMessage/Receive...` | IAM | Async notification flow |
| Lambda → SES | `ses:SendEmail` | IAM | Deliver emails |
| EventBridge → cleanup Lambda | `aws_cloudwatch_event_rule` + permission | Event | Scheduled cleanup |
| SQS → notification Lambda | `aws_lambda_event_source_mapping` | Event | Trigger on messages |
| Lambda → RDS | Security/DB creds from Secrets | Network | DB read/write ops |
| Backend ECS → SQS | (via app code, IAM task role) | Network/API | Enqueue notifications |

---

## 3. External User → Frontend (Next.js) → Infrastructure

This section traces requests from the **user's browser (outside world)** through the Next.js
frontend and back into the AWS infrastructure — the complete public user journey.

### 3.1 Browsing the app

```
User browser (outside the VPC, on the internet)
   │
   │ 1. Types/manages the Amplify URL
   │    https://master.dagmy4k986aae.amplifyapp.com
   │
   │ 2. DNS resolves to CloudFront edge
   ▼
AWS Amplify (App: task-manager-dev, master branch)
   │
   │ 3. Serves static Next.js build (out/): index.html, login.html,
   │    register.html, JS, CSS, images — from Amplify's S3 bucket + CDN
   ▼
Browser renders the Next.js SPA (React client-side app)
```

- The user never touches the VPC, ECS, RDS, or Redis directly — the frontend is 100% static
  assets served by Amplify/CloudFront.
- The SPA is a **static export** (`output: "export"`, `baseDirectory: out`); there is **no
  SSR/Node server** and no internet-facing Next.js server in the VPC.

### 3.2 User performs an action (e.g., login, create a task)

```
Browser SPA (Next.js client)
   │
   │ 4. Frontend calls the backend API using NEXT_PUBLIC_API_URL
   │    (currently) http://task-manager-dev-<...>.eu-west-2.elb.amazonaws.com/api
   │    e.g. POST /api/auth/token/  ,  POST /api/tasks/  ,  GET /api/me/
   │
   ▼ (request exits Amplify, travels over the public internet)
   │
   │ 5. DNS resolves the ALB DNS name  ──►  Public traffic hits the ALB port 80 (HTTP)
   ▼
Application Load Balancer (task-manager-dev, internet-facing)
   │
   │ 6. ALB listener (HTTP :80) forwards to the backend target group (IP mode)
   ▼
ECS Fargate — Backend task (Django REST Framework, :8000, private subnet)
   │
   │ 7. Django handles the request
   │    • JWT auth validated
   │    • reads DB creds from Secrets Manager (via task role)
   │    • queries PostgreSQL (RDS, :5432)
   │    • hits Redis cache/sessions if needed (:6379)
   │    • writes logs to CloudWatch  /ecs/task-manager-dev
   ▼
Response JSON returned:  ALB ──► Amplify/browser ──► SPA re-renders UI
```

### 3.3 Where the security boundaries sit for a user request

| Hop | Network boundary | Security control |
|-----|------------------|------------------|
| Browser → Amplify | Public internet | Amplify/CloudFront HTTPS, Amplify IAM role |
| Browser → ALB → ECS | Public internet → VPC | ALB SG (80/443 from `0.0.0.0/0`) → backend SG (8000 from ALB) |
| ECS → RDS | Private (inside VPC) | RDS SG (5432 from backend SG only), RDS not publicly accessible |
| ECS → Redis | Private (inside VPC) | Redis SG (6379 from backend SG only), encryption in transit |

### 3.4 Request path summary (end-to-end)

```
User Browser
   │
   ├──► (read/static)  ──► AWS Amplify / CloudFront ──► S3 static Next.js build
   │
   └──► (API data)     ──► ALB (public) ──► ECS Fargate backend ──► RDS / Redis / Secrets
```

> **Current limitation (Track B):** the ALB currently exposes **HTTP :80 only** (no cert in
> Terraform), while the frontend is served over **HTTPS**. Modern browsers therefore block API
> calls as **mixed content**. Enabling HTTPS on the ALB (domain + ACM cert) is the pending
> follow-up to make end-to-end user requests work from the browser.

---

## 4. Data / Dependency Flow (Terraform graph)

The root `main.tf` wires modules together. Dependencies that matter:

- `alb` depends on `vpc` (subnets, VPC id)
- `ecr` is independent (only images)
- `rds`, `redis` depend on `vpc` (subnets) and their **security groups**
- `secrets` depends on `rds.endpoint` + `redis.endpoint` (embeds hosts in secret strings)
- `ecs` depends on `alb` (target group), `iam` (roles), `secrets` (ARNs), `cloudwatch` (log group), `vpc` (subnets), and the backend SG
- `iam` depends on `ecr`, `secrets`, `amplify`, `lambda`, and creates OIDC provider
- `amplify` depends on `ecr` (backend repo ARN) and `alb` (via `api_url` local)
- `lambda` depends on `secrets`, `cloudwatch`
- `cloudwatch` depends on ECS/ALB (metric dimensions) though created independently

```
vpc ──► alb ──► ecs ──► rds / redis / (cloudwatch)
  │      │                    │
  │      └────► amplify ◄──┐  └────► secrets ──► iam
  │                        │               │
  ecr ─────────────────────┼──────► iam ───┘
                           │
  lambda ◄── secrets ◄─────┘
  cloudwatch ◄── ecs, alb
```

---

## 5. Security Groups Matrix

| SG | Inbound | Source | Outbound |
|----|---------|--------|----------|
| ALB SG | 80, 443 | `0.0.0.0/0` | all |
| Backend SG | 8000 | ALB SG only | all |
| RDS SG | 5432 | Backend SG only | (default all) |
| Redis SG | 6379 | Backend SG only | (default all) |

---

## 6. Notable Config Details & Current Gaps

- **ALB listener is HTTP-only** right now (`certificate_arn` empty → only the `http` listener is created). The Amplify frontend is HTTPS, so browser API calls hit an HTTP endpoint → **mixed-content block** (a known pending follow-up, Track B).
- **RDS is single-instance** (`aws_db_instance`), not Aurora. `ARCHITECTURE.md` mentions Aurora — this document reflects the actual code (Postgres 16.14).
- **Redis endpoint** is a replication group with `num_cache_clusters = 1`, no Multi-AZ.
- **Deployment**: `deploy.yml` runs DB migrations via a **one-off ECS task** (same image, overridden command `migrate --noinput`) before `update-service`.
- **Frontend** is a **static export** (`output: "export"`, `baseDirectory: out` in the Amplify build spec) served by Amplify's CDN — it is **not** deployed to ECS.
- The `task-manager-dev-ecs-execution` role uses the managed `AmazonECSTaskExecutionRolePolicy`, plus custom inline policies for secrets/logs/ECR.
