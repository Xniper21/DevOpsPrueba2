# 🚀 CI/CD & Terraform Deployment Guide

**Complete automated deployment pipeline for Innovatech FullStack application on AWS**

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Architecture Overview](#architecture-overview)
3. [Workflow Diagram](#workflow-diagram)
4. [Detailed Setup](#detailed-setup)
5. [File Structure](#file-structure)
6. [Troubleshooting](#troubleshooting)

---

## ⚡ Quick Start

### For Linux/macOS:
```bash
# 1. Make scripts executable
chmod +x scripts/setup-cicd-aws.sh

# 2. Run AWS setup (creates OIDC, IAM roles, S3, DynamoDB)
./scripts/setup-cicd-aws.sh \
  --github-org YOUR_ORG \
  --github-repo proyectofullstack2 \
  --aws-region us-east-1

# 3. Add GitHub Secrets from the output
# Go to: Settings → Secrets and variables → Actions → New repository secret

# 4. Initialize Terraform
cd terraform
terraform init \
  -backend-config="bucket=innovatech-terraform-state-ACCOUNT_ID" \
  -backend-config="key=main/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=innovatech-terraform-locks"

# 5. Push to develop to trigger CI
git checkout develop
git push origin develop
```

### For Windows (PowerShell):
```powershell
# 1. Run AWS setup
.\scripts\setup-cicd-aws.ps1 `
  -GitHubOrg YOUR_ORG `
  -GitHubRepo proyectofullstack2 `
  -AwsRegion us-east-1

# 2. Add GitHub Secrets from the output

# 3. Continue with Terraform setup...
```

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS Infrastructure                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Internet (0.0.0.0/0)                        │  │
│  └─────────────────────┬────────────────────────────────┘  │
│                        │                                    │
│  ┌──────────────────────▼────────────────────────────────┐  │
│  │  Application Load Balancer (Port 80)                │  │
│  │  ├─ / → Frontend (React + Nginx)                    │  │
│  │  ├─ /api/ventas/* → Ventas API (Spring Boot)       │  │
│  │  └─ /api/despachos/* → Despacho API (Spring Boot)  │  │
│  └───┬─────────────────────────────────────────────────┘  │
│      │                                                     │
│  ┌───▼──────────────────────────────────────────────────┐  │
│  │  VPC (10.0.0.0/16)                                  │  │
│  │                                                      │  │
│  │  ┌───────────────────┐    ┌───────────────────┐    │  │
│  │  │ Public Subnets    │    │ Private Subnets   │    │  │
│  │  │ 10.0.1.0/24       │    │ 10.0.11.0/24      │    │  │
│  │  │ 10.0.2.0/24       │    │ 10.0.12.0/24      │    │  │
│  │  └─────────┬─────────┘    └────────┬──────────┘    │  │
│  │            │                       │               │  │
│  │   ┌────────▼──────────┐  ┌────────▼────────────┐   │  │
│  │   │  NAT Gateway      │  │  ECS Fargate Tasks  │   │  │
│  │   │  (outbound only)  │  │  ├─ Ventas API      │   │  │
│  │   └───────────────────┘  │  ├─ Despacho API    │   │  │
│  │                          │  └─ Frontend        │   │  │
│  │                          └────────┬────────────┘   │  │
│  │                                   │                │  │
│  │                          ┌────────▼────────────┐   │  │
│  │                          │  RDS MySQL 8.0      │   │  │
│  │                          │  (Multi-AZ)         │   │  │
│  │                          └─────────────────────┘   │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 📊 Workflow Diagram

```
GitHub Repository
     │
     ├─────────────────────────────────────────────────────────┐
     │                                                         │
     ▼ (Push to develop)                              (PR/Push to main)
     
CI WORKFLOW                                          CD WORKFLOW
ci-develop.yml                                       cd-deploy.yml
     │                                                    │
     ├─ Test Ventas API                               ├─ Build & Push to ECR
     │  (Maven + Tests)                               │  ├─ Ventas API
     │                                                 │  ├─ Despacho API
     ├─ Test Despacho API                            │  └─ Frontend
     │  (Maven + Tests)                               │
     │                                                 ├─ (On PR)
     ├─ Test Frontend                                │  └─ Terraform Plan
     │  (ESLint + Build)                             │     (comment on PR)
     │                                                 │
     ├─ Build Docker Images                          ├─ (After merge to main)
     │  (no push)                                     └─ Terraform Apply
     │                                                    ├─ Update VPC
     └─ Report Status                                   ├─ Update RDS
        ✓ Pass / ✗ Fail                              ├─ Update ECS
                                                      └─ Output URLs
```

---

## 📁 File Structure

```
.github/
├── workflows/
│   ├── ci-develop.yml         # CI pipeline (develop branch)
│   └── cd-deploy.yml          # CD pipeline (main branch)

terraform/
├── versions.tf                # Terraform version constraints
├── variables.tf               # Input variables
├── main.tf                    # Main infrastructure resources
├── outputs.tf                 # Output values
├── terraform.tfvars.example   # Example variables (copy & edit)
├── .gitignore                # Terraform ignore rules
└── README.md                  # Detailed Terraform docs

scripts/
├── setup-cicd-aws.sh          # AWS setup script (Linux/macOS)
├── setup-cicd-aws.ps1         # AWS setup script (Windows PowerShell)
├── push-to-ecr.sh             # Manual ECR push script
├── local-dev.sh               # Local development setup
└── init.sql                   # Database initialization

CI_CD_SETUP_GUIDE.md           # Complete setup guide
CI_CD_COMPLETE_README.md       # This file
```

---

## 🔧 Detailed Setup

### Step 1: Run AWS Infrastructure Setup

**Linux/macOS:**
```bash
chmod +x scripts/setup-cicd-aws.sh
./scripts/setup-cicd-aws.sh \
  --github-org $(git config --global github.user) \
  --github-repo proyectofullstack2
```

**Windows PowerShell:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\scripts\setup-cicd-aws.ps1 -GitHubOrg "YOUR_ORG"
```

This script will:
- ✅ Create OIDC provider for GitHub
- ✅ Create IAM role with federated trust
- ✅ Create S3 bucket for Terraform state
- ✅ Create DynamoDB table for state locking
- ✅ Output all required GitHub Secrets

### Step 2: Add GitHub Secrets

Go to: **Settings → Secrets and variables → Actions**

Add these secrets:

| Secret Name | Value |
|------------|-------|
| `AWS_ROLE_TO_ASSUME` | `arn:aws:iam::ACCOUNT_ID:role/github-actions-terraform` |
| `TF_STATE_BUCKET` | `innovatech-terraform-state-ACCOUNT_ID` |
| `TF_STATE_DYNAMODB` | `innovatech-terraform-locks` |
| `VITE_API_URL_VENTAS` | `https://your-domain/api/ventas` |
| `VITE_API_URL_DESPACHOS` | `https://your-domain/api/despachos` |

### Step 3: Initialize Terraform

```bash
cd terraform

# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

**Edit terraform.tfvars:**
```hcl
environment = "production"
db_password = "YourSecurePassword123!"
ecs_desired_count = 2
enable_autoscaling = true
```

**Initialize Terraform backend:**
```bash
terraform init \
  -backend-config="bucket=innovatech-terraform-state-ACCOUNT_ID" \
  -backend-config="key=main/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="encrypt=true" \
  -backend-config="dynamodb_table=innovatech-terraform-locks"
```

### Step 4: Test Locally (Optional)

```bash
cd terraform

terraform plan \
  -var="ventas_api_image=YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech/ventas-api:latest" \
  -var="despacho_api_image=YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech/despacho-api:latest" \
  -var="frontend_image=YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech/frontend:latest" \
  -var="environment=production"
```

### Step 5: Trigger Workflows

**CI Workflow (develop):**
```bash
git checkout develop
git commit --allow-empty -m "Trigger CI workflow"
git push origin develop
```

**CD Workflow (main):**
```bash
git checkout main
git pull origin develop
git push origin main
```

---

## 📈 How It Works

### CI Workflow (develop branch)
1. **Trigger**: Push to `develop` or PR to `develop`
2. **Tests**:
   - Run Maven tests for Ventas API
   - Run Maven tests for Despacho API
   - Run ESLint + build for Frontend
3. **Docker Build**: Build images (no push)
4. **Caching**: Use GitHub's cache for faster builds
5. **Reports**: Upload test reports as artifacts

### CD Workflow (main branch)
1. **Trigger**: PR to `main` or push to `main`
2. **Docker Build & Push**:
   - Build Ventas API image → Push to ECR
   - Build Despacho API image → Push to ECR
   - Build Frontend image → Push to ECR
3. **Terraform Plan** (PR only):
   - Show what will change
   - Comment plan on PR for review
4. **Terraform Apply** (Push only):
   - Update all infrastructure
   - Deploy new services
   - Output endpoints

---

## 🔒 Security Features

✅ **OIDC Federated Authentication**: No long-lived AWS keys
✅ **Encrypted State**: Terraform state encrypted in S3
✅ **Secrets Management**: Database passwords in AWS Secrets Manager
✅ **Private Network**: RDS & ECS in private subnets
✅ **Security Groups**: Restricted ingress/egress rules
✅ **No Public Database**: RDS not accessible from internet
✅ **Minimal IAM**: Services use least-privilege roles

---

## 📊 Infrastructure Scaling

### Vertical Scaling (more power per task)
```hcl
# In terraform.tfvars
ecs_task_cpu = "512"        # was 256
ecs_task_memory = "1024"    # was 512
```

### Horizontal Scaling (more tasks)
```hcl
# In terraform.tfvars
ecs_desired_count = 4       # was 2
```

### Auto-scaling
```hcl
# In terraform.tfvars
enable_autoscaling = true   # targets 70% CPU
```

---

## 🐛 Troubleshooting

### CI Workflow Fails

**Check backend tests:**
```bash
cd back-Ventas_SpringBoot/Springboot-API-REST
mvn clean test

cd ../../back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO
mvn clean test
```

**Check frontend tests:**
```bash
cd front_despacho
npm ci
npm run lint
npm run build
```

### CD Workflow Fails

**Check Terraform syntax:**
```bash
cd terraform
terraform validate
```

**Check AWS credentials:**
```bash
aws sts get-caller-identity
```

**Check S3 backend:**
```bash
aws s3 ls | grep terraform-state
```

### Application Not Accessible

```bash
# Get ALB URL
aws elbv2 describe-load-balancers \
  --query "LoadBalancers[*].[DNSName]" \
  --output text

# Check ECS tasks
aws ecs list-tasks \
  --cluster innovatech-cluster

# View logs
aws logs tail /ecs/innovatech --follow
```

---

## 📚 Documentation

- **Full Setup Guide**: [CI_CD_SETUP_GUIDE.md](CI_CD_SETUP_GUIDE.md)
- **Terraform Docs**: [terraform/README.md](terraform/README.md)
- **GitHub Actions Docs**: [GitHub Documentation](https://docs.github.com/en/actions)
- **AWS Documentation**: [AWS Docs](https://docs.aws.amazon.com/)

---

## ✅ Checklist

- [ ] AWS account created
- [ ] AWS CLI installed & configured
- [ ] GitHub repository ready
- [ ] Run `setup-cicd-aws.sh` or `.ps1`
- [ ] Added GitHub Secrets
- [ ] Terraform initialized
- [ ] terraform.tfvars configured
- [ ] Test commit to develop (triggers CI)
- [ ] Create PR to main (triggers CD plan)
- [ ] Review and approve infrastructure changes
- [ ] Merge to main (triggers CD apply)
- [ ] Application deployed! ✨

---

## 🎉 You're Done!

Your application is now fully automated with:
- ✅ Continuous Integration (tests on every commit to develop)
- ✅ Continuous Deployment (auto-deploy to AWS on merge to main)
- ✅ Infrastructure as Code (Terraform)
- ✅ Scalable & Secure Architecture

### Access Your Application:
```
Frontend: http://ALB-DNS-NAME/
Ventas API: http://ALB-DNS-NAME/api/ventas
Despacho API: http://ALB-DNS-NAME/api/despachos
```

### View Logs:
```bash
# Real-time logs
aws logs tail /ecs/innovatech --follow

# All infrastructure details
cd terraform
terraform output
```

---

## 📞 Support

Need help? Check:
1. [CI_CD_SETUP_GUIDE.md](CI_CD_SETUP_GUIDE.md) - Detailed setup instructions
2. [terraform/README.md](terraform/README.md) - Terraform-specific docs
3. GitHub Actions logs in **Actions** tab
4. AWS CloudWatch logs
5. Terraform state debugging

---

**Happy Deploying! 🚀**
