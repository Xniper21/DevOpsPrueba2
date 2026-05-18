# 🚀 Innovatech CI/CD & Terraform - Quick Reference

## 📋 What's Been Created

### Workflows (.github/workflows/)

#### 1. **ci-develop.yml** - Continuous Integration
- **Trigger**: Push/PR to `develop` branch
- **Jobs**:
  - Test Ventas API (Maven)
  - Test Despacho API (Maven)
  - Test Frontend (ESLint + Build)
  - Build Docker images (no push)
- **Artifacts**: Test reports, build logs
- **Duration**: ~5-10 minutes

#### 2. **cd-deploy.yml** - Continuous Deployment
- **Trigger**: PR to `main` or push to `main`
- **Jobs on PR**:
  - Build & push images to ECR
  - Terraform plan (commented on PR)
- **Jobs on Push**:
  - Build & push images to ECR
  - Terraform apply (deploy infrastructure)
  - Output endpoints
- **Duration**: ~10-15 minutes

### Terraform Configuration (terraform/)

#### Core Files
- **versions.tf**: Terraform & provider versions
- **variables.tf**: Input variables with validation
- **main.tf**: Complete infrastructure (VPC, RDS, ECS, ALB, etc.)
- **outputs.tf**: Output values (URLs, endpoints)
- **terraform.tfvars.example**: Example configuration

#### Infrastructure Created
- **VPC**: 10.0.0.0/16 with public & private subnets
- **RDS**: MySQL 8.0 with Multi-AZ (production)
- **ECS Fargate**: 3 services (Ventas API, Despacho API, Frontend)
- **ALB**: Application Load Balancer with path-based routing
- **Auto Scaling**: CPU-based (70% target)
- **Security**: Security groups, private subnets, encryption

### Setup Scripts

#### Linux/macOS
```bash
./scripts/setup-cicd-aws.sh
```
- Creates OIDC provider
- Creates IAM role
- Creates S3 backend bucket
- Creates DynamoDB lock table
- Outputs GitHub Secrets

#### Windows PowerShell
```powershell
.\scripts\setup-cicd-aws.ps1
```
- Same as above, PowerShell version

### Documentation

- **CI_CD_SETUP_GUIDE.md**: Complete setup instructions
- **CI_CD_COMPLETE_README.md**: Overview & quick start
- **terraform/README.md**: Terraform-specific documentation

---

## ⚡ Quick Start (5 minutes)

### 1. Run AWS Setup
```bash
chmod +x scripts/setup-cicd-aws.sh
./scripts/setup-cicd-aws.sh \
  --github-org YOUR_GITHUB_ORG \
  --github-repo proyectofullstack2
```

### 2. Copy GitHub Secrets
```
AWS_ROLE_TO_ASSUME=arn:aws:iam::ACCOUNT_ID:role/github-actions-terraform
TF_STATE_BUCKET=innovatech-terraform-state-ACCOUNT_ID
TF_STATE_DYNAMODB=innovatech-terraform-locks
VITE_API_URL_VENTAS=https://your-domain/api/ventas
VITE_API_URL_DESPACHOS=https://your-domain/api/despachos
```

### 3. Initialize Terraform
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init \
  -backend-config="bucket=innovatech-terraform-state-ACCOUNT_ID" \
  -backend-config="key=main/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="encrypt=true" \
  -backend-config="dynamodb_table=innovatech-terraform-locks"
```

### 4. Test Workflows
```bash
# Push to develop (triggers CI)
git checkout develop
git commit --allow-empty -m "Test CI"
git push origin develop

# Create PR to main (triggers CD plan)
git checkout main
git pull origin develop
# Create PR through GitHub

# Merge to main (triggers CD apply)
git merge develop
git push origin main
```

---

## 📊 Workflow Triggers

```
DEVELOP BRANCH
  │
  ├─→ Any commit/PR
      ↓
      CI RUNS
      ├─ Test Ventas API
      ├─ Test Despacho API
      ├─ Test Frontend
      └─ Build Docker Images
      
MAIN BRANCH
  │
  ├─→ PR opened
      ↓
      CD PLAN RUNS
      ├─ Build & Push to ECR
      ├─ Terraform Plan
      └─ Comment on PR
      
  ├─→ PR merged/push
      ↓
      CD APPLY RUNS
      ├─ Build & Push to ECR
      ├─ Terraform Apply
      └─ Output URLs
```

---

## 🔐 GitHub Secrets Required

```
AWS_ROLE_TO_ASSUME              # ARN of IAM role
TF_STATE_BUCKET                 # S3 bucket name
TF_STATE_DYNAMODB               # DynamoDB table name
VITE_API_URL_VENTAS            # Frontend API URL (optional)
VITE_API_URL_DESPACHOS         # Frontend API URL (optional)
```

---

## 🎯 Environment Variables

### Terraform Variables (terraform.tfvars)
```hcl
aws_region           = "us-east-1"
environment          = "production"
ventas_api_image     = "ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/innovatech/ventas-api:latest"
despacho_api_image   = "ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/innovatech/despacho-api:latest"
frontend_image       = "ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/innovatech/frontend:latest"
db_password          = "YourSecurePassword123!"
ecs_desired_count    = 2
enable_autoscaling   = true
```

---

## 📱 URLs After Deployment

```
Frontend:           http://ALB_DNS_NAME/
Ventas API:         http://ALB_DNS_NAME/api/ventas
Despacho API:       http://ALB_DNS_NAME/api/despachos
CloudWatch Logs:    /ecs/innovatech
```

---

## 🔧 Manual Commands

### Check Deployment Status
```bash
# Get ALB DNS name
aws elbv2 describe-load-balancers \
  --query "LoadBalancers[*].[DNSName]" --output text

# Check ECS services
aws ecs describe-services \
  --cluster innovatech-cluster \
  --services innovatech-ventas-api-service

# View logs
aws logs tail /ecs/innovatech --follow
```

### Scaling
```bash
# Get terraform outputs
cd terraform && terraform output

# Scale services
aws ecs update-service \
  --cluster innovatech-cluster \
  --service innovatech-frontend-service \
  --desired-count 4
```

### Destroy Infrastructure
```bash
cd terraform
terraform destroy \
  -var="environment=production" \
  -auto-approve
```

---

## 🆘 Troubleshooting Quick Fixes

| Issue | Solution |
|-------|----------|
| CI tests fail | `mvn clean test` locally, check logs |
| Docker build fails | Check Dockerfile syntax, ensure dependencies installed |
| ECR push fails | Verify AWS credentials, check IAM permissions |
| Terraform init fails | Check S3 bucket exists, DynamoDB table exists |
| ECS tasks failing | Check CloudWatch logs, verify environment vars |
| ALB health checks failing | Verify security groups, check app startup logs |

---

## 📚 Additional Resources

- **AWS ECS**: https://docs.aws.amazon.com/ecs/
- **AWS RDS**: https://docs.aws.amazon.com/rds/
- **Terraform Docs**: https://www.terraform.io/docs/
- **GitHub Actions**: https://docs.github.com/en/actions
- **Spring Boot**: https://spring.io/projects/spring-boot
- **React**: https://react.dev/

---

## ✅ Verification Checklist

After deployment, verify:

- [ ] CI workflow runs on commits to develop
- [ ] Tests pass for all services
- [ ] CD workflow triggers on PR to main
- [ ] Terraform plan shows expected changes
- [ ] CD applies changes on merge to main
- [ ] ALB is healthy
- [ ] ECS services running (desired count = running count)
- [ ] RDS database accessible
- [ ] Frontend loads in browser
- [ ] API endpoints respond
- [ ] Logs appear in CloudWatch

---

## 🎉 Summary

**You now have:**
- ✅ Automated CI on develop (test + build)
- ✅ Automated CD on main (deploy to AWS)
- ✅ Infrastructure as Code (Terraform)
- ✅ Secure AWS setup (OIDC, encrypted state)
- ✅ Scalable & highly available architecture
- ✅ Complete monitoring & logging

**Start using it:**
1. Push to develop → CI runs tests
2. Create PR to main → CD shows plan
3. Merge to main → CD deploys

---

**Last Updated**: 2024
**Version**: 1.0.0
