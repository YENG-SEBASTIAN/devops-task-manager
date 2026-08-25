````markdown
# DevOps Task Manager

A production-oriented task management platform built with **Next.js** and **Django REST Framework**, designed as a hands-on project for learning modern **DevOps, containerization, CI/CD, AWS, and Kubernetes**.

The application will progressively evolve from a simple full-stack application into a production-style cloud-native system.

---

## 🚀 Project Goal

The primary goal of this project is not just to build a task management application.

It is to learn how to take a software application from:

```text
Local Development
       ↓
Docker
       ↓
Docker Compose
       ↓
CI/CD
       ↓
AWS
       ↓
Container Registry
       ↓
Kubernetes
       ↓
AWS EKS
       ↓
Production
````

Throughout the project, we will intentionally introduce real-world infrastructure problems and learn how to diagnose and solve them.

---

## 🏗️ Planned Architecture

The application will eventually consist of:

```text
                         ┌───────────────┐
                         │    Users      │
                         └───────┬───────┘
                                 │
                                 ▼
                         ┌───────────────┐
                         │    Next.js    │
                         │   Frontend    │
                         └───────┬───────┘
                                 │
                                 ▼
                         ┌───────────────┐
                         │    Django     │
                         │   REST API    │
                         └───────┬───────┘
                                 │
              ┌──────────────────┼──────────────────┐
              │                  │                  │
              ▼                  ▼                  ▼
       ┌────────────┐      ┌────────────┐    ┌────────────┐
       │ PostgreSQL │      │   Redis    │    │    S3      │
       └────────────┘      └─────┬──────┘    └────────────┘
                                 │
                                 ▼
                           ┌───────────┐
                           │  Celery   │
                           │  Worker   │
                           └───────────┘
```

The architecture will evolve as we progress through the DevOps learning phases.

---

## 🛠️ Technology Stack

### Frontend

* Next.js
* React
* TypeScript
* Tailwind CSS

### Backend

* Python
* Django
* Django REST Framework
* JWT Authentication

### Database

* PostgreSQL

### Caching & Background Jobs

* Redis
* Celery

### Containerization

* Docker
* Docker Compose

### CI/CD

* GitHub Actions

### Cloud

* AWS
* Amazon ECR
* Amazon ECS
* AWS Fargate
* Amazon EKS
* Amazon RDS
* Amazon S3
* Application Load Balancer
* CloudWatch
* IAM
* Secrets Manager

### Kubernetes

* Kubernetes
* Deployments
* Pods
* Services
* ConfigMaps
* Secrets
* Ingress
* Persistent Volumes
* StatefulSets
* Jobs/CronJobs
* Horizontal Pod Autoscaling
* Helm
* Amazon EKS

---

# 📚 DevOps Learning Roadmap

This project will be developed in phases.

## Phase 1 — Docker Fundamentals

Learn:

* Docker architecture
* Docker Engine
* Docker CLI
* Images
* Containers
* Container lifecycle
* `docker run`
* `docker ps`
* `docker stop`
* `docker start`
* `docker restart`
* `docker rm`
* `docker logs`
* `docker exec`
* `docker inspect`
* `docker stats`

---

## Phase 2 — Docker Images & Dockerfiles

Learn:

* Dockerfiles
* `FROM`
* `RUN`
* `COPY`
* `ADD`
* `WORKDIR`
* `ENV`
* `ARG`
* `EXPOSE`
* `CMD`
* `ENTRYPOINT`
* `.dockerignore`
* Docker image layers
* Build cache
* Image optimization
* Multi-stage builds

---

## Phase 3 — Docker Networking

Learn:

* Container networking
* Bridge networks
* Host networking
* Port mapping
* Container DNS
* Service discovery
* Container-to-container communication

Example:

```text
Django Container
       │
       │ Docker Network
       ▼
PostgreSQL Container
```

---

## Phase 4 — Docker Volumes & Storage

Learn:

* Docker volumes
* Bind mounts
* Temporary storage
* Persistent data
* Database persistence
* Volume backups

Example:

```text
PostgreSQL Container
        │
        ▼
PostgreSQL Volume
        │
        ▼
Persistent Database Data
```

---

## Phase 5 — Docker Compose

Containerize the complete development environment:

```text
┌───────────────────────────────────────┐
│            Docker Compose             │
│                                       │
│  ┌─────────┐   ┌──────────┐          │
│  │ Next.js │   │  Django  │          │
│  └─────────┘   └────┬─────┘          │
│                     │                │
│              ┌──────┴──────┐         │
│              ▼             ▼         │
│         PostgreSQL       Redis       │
│                            │          │
│                            ▼          │
│                         Celery       │
└───────────────────────────────────────┘
```

Learn:

* `compose.yaml`
* Services
* Networks
* Volumes
* Environment variables
* Service dependencies
* Health checks
* Compose commands
* Development vs production configuration

---

# Phase 6 — Production Docker

Learn how to build production-ready images.

Topics include:

* Minimal base images
* Image size optimization
* Multi-stage builds
* Non-root containers
* Container security
* Secrets
* Health checks
* Resource limits
* Logging
* Graceful shutdown
* Production application servers

---

# Phase 7 — CI/CD

Introduce automated pipelines using GitHub Actions.

```text
Developer
    │
    ▼
git push
    │
    ▼
GitHub
    │
    ▼
GitHub Actions
    │
    ├── Run tests
    ├── Build Docker image
    ├── Security scan
    └── Push image
```

Learn:

* GitHub Actions
* CI pipelines
* CD pipelines
* Automated testing
* Docker builds
* Image tagging
* Image versioning
* Secrets management
* Deployment automation

---

# Phase 8 — AWS & Container Registry

Move our Docker images into AWS.

```text
GitHub Actions
      │
      ▼
Docker Build
      │
      ▼
Amazon ECR
```

Learn:

* AWS IAM
* Amazon ECR
* Docker authentication
* Image repositories
* Image tags
* Image lifecycle policies

---

# Phase 9 — AWS ECS & Fargate

Deploy the application using AWS ECS.

```text
                    Internet
                       │
                       ▼
                Application
               Load Balancer
                       │
                       ▼
                  ECS Service
                       │
              ┌────────┴────────┐
              ▼                 ▼
         Django Task       Next.js Task
```

Learn:

* ECS clusters
* Task definitions
* ECS services
* Fargate
* Load balancers
* Target groups
* Auto scaling
* IAM roles
* CloudWatch
* Service discovery

---

# Phase 10 — Kubernetes

After gaining strong Docker fundamentals, we introduce Kubernetes.

Learn:

* Kubernetes architecture
* Control plane
* Nodes
* Pods
* Deployments
* ReplicaSets
* Services
* Namespaces
* ConfigMaps
* Secrets
* Ingress
* Persistent Volumes
* Persistent Volume Claims
* StatefulSets
* Jobs
* CronJobs
* Health probes
* Resource requests
* Resource limits
* Horizontal Pod Autoscaling

Basic architecture:

```text
                    Kubernetes Cluster
                           │
             ┌─────────────┴─────────────┐
             │                           │
        ┌────▼────┐                 ┌────▼────┐
        │  Node   │                 │  Node   │
        │         │                 │         │
        │ ┌─────┐ │                 │ ┌─────┐ │
        │ │ Pod │ │                 │ │ Pod │ │
        │ └─────┘ │                 │ └─────┘ │
        └─────────┘                 └─────────┘
```

---

# Phase 11 — Kubernetes on AWS

Deploy the application to **Amazon EKS**.

```text
                    AWS
                     │
                     ▼
              Amazon EKS
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
     Frontend      Backend      Workers
        │            │            │
        │            ├──────┐     │
        │            ▼      ▼     │
        │          RDS    Redis   │
        │
        └───────────────┐
                        ▼
                       S3
```

Learn:

* EKS
* Kubernetes on AWS
* ECR + EKS
* IAM Roles for Service Accounts
* Load Balancers
* AWS networking
* Persistent storage
* Kubernetes secrets
* CloudWatch
* Auto scaling

---

# Phase 12 — Production CI/CD

The final pipeline will look approximately like:

```text
                         Developer
                             │
                             ▼
                           GitHub
                             │
                             ▼
                      GitHub Actions
                             │
             ┌───────────────┼───────────────┐
             │               │               │
             ▼               ▼               ▼
           Tests          Security       Docker Build
                                             │
                                             ▼
                                          Amazon ECR
                                             │
                                             ▼
                                            EKS
                                             │
                         ┌───────────────────┼───────────────────┐
                         │                   │                   │
                         ▼                   ▼                   ▼
                    Next.js Pods       Django Pods        Celery Pods
                         │                   │                   │
                         │                   ├──────┐            │
                         │                   ▼      ▼            │
                         │                  RDS   Redis          │
                         │
                         └──────────────────────────────────────
```

---

# 📋 Application Features

The Task Manager will eventually support:

## Authentication

* User registration
* Login
* Logout
* JWT authentication
* Token refresh
* Protected API endpoints

## Projects

* Create projects
* Update projects
* Delete projects
* Project members
* Project permissions

## Tasks

* Create tasks
* Update tasks
* Delete tasks
* Assign tasks
* Task priorities
* Task status
* Due dates
* Task filtering
* Task searching

## Activity Tracking

Track events such as:

```text
User created task
User updated task
User changed task priority
User assigned task
User completed task
```

## Background Processing

Use Celery for tasks such as:

* Notifications
* Scheduled tasks
* Email processing
* Activity processing

---

# 🎯 Learning Objectives

By completing this project, the goal is to understand how to:

* Build a full-stack application
* Containerize applications
* Build and optimize Docker images
* Manage multi-container applications
* Configure Docker networking
* Persist container data
* Debug containers
* Build CI/CD pipelines
* Store container images in a registry
* Deploy containers to AWS
* Understand ECS and Fargate
* Understand Kubernetes
* Deploy applications to Kubernetes
* Use Amazon EKS
* Monitor production workloads
* Troubleshoot distributed applications
* Design scalable deployment architectures

---

# 🧑‍💻 Local Development

## Clone the repository

```bash
git clone <repository-url>
cd devops-task-manager
```

## Backend

```bash
cd backend

python -m venv .venv
source .venv/bin/activate

pip install -r requirements.txt
```

Run Django:

```bash
python manage.py runserver
```

Backend:

```text
http://localhost:8000
```

## Frontend

```bash
cd frontend

npm install
npm run dev
```

Frontend:

```text
http://localhost:3000
```

---

# 🐳 Docker

Docker will be introduced progressively during the project.

Eventually the entire development environment will be started with:

```bash
docker compose up
```

Run in detached mode:

```bash
docker compose up -d
```

Stop services:

```bash
docker compose down
```

View logs:

```bash
docker compose logs
```

---

# ☸️ Kubernetes

Kubernetes will be introduced after completing the Docker and container orchestration fundamentals.

Kubernetes manifests will eventually be organized under:

```text
k8s/
├── namespace.yaml
├── configmap.yaml
├── secret.yaml
├── deployment.yaml
├── service.yaml
├── ingress.yaml
└── hpa.yaml
```

---

# 🔐 Security

Security will be treated as part of the DevOps lifecycle.

Topics will include:

* Environment variables
* Secret management
* IAM
* Least privilege
* Container security
* Non-root containers
* Image scanning
* Dependency scanning
* Secure CI/CD pipelines
* Kubernetes Secrets
* AWS Secrets Manager

Sensitive values should **never be committed to Git**.

---

# 📈 Project Philosophy

This project intentionally follows an incremental approach.

We will not start with Kubernetes, AWS, or a complicated infrastructure setup.

Instead:

```text
Understand
    ↓
Build
    ↓
Containerize
    ↓
Break
    ↓
Debug
    ↓
Improve
    ↓
Automate
    ↓
Deploy
    ↓
Scale
```

Every technology should solve a problem introduced by the previous stage.

---

# 🗺️ Long-Term Architecture

The final goal is a cloud-native architecture capable of running reliably at scale:

```text
                         Internet
                            │
                            ▼
                     AWS Load Balancer
                            │
                            ▼
                       Amazon EKS
                            │
              ┌─────────────┼─────────────┐
              │             │             │
              ▼             ▼             ▼
          Next.js        Django        Celery
            Pods           Pods          Pods
                            │             │
                  ┌─────────┼─────────────┤
                  │         │             │
                  ▼         ▼             ▼
                 RDS      Redis          S3
              PostgreSQL
```

With CI/CD:

```text
Developer
    │
    ▼
GitHub
    │
    ▼
GitHub Actions
    │
    ├── Test
    ├── Build
    ├── Scan
    └── Push
         │
         ▼
      Amazon ECR
         │
         ▼
       EKS
         │
         ▼
    Production
```

---

## 📌 Status

🚧 **Currently in development**

The project is being built incrementally as a practical learning journey through:

**Docker → CI/CD → AWS → Kubernetes → EKS**

---

## 📄 License

This project is intended primarily as a learning and portfolio project.

```
```
