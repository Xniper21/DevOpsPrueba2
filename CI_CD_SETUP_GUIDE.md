# CI/CD Workflow Documentation

## 🔄 Complete Workflow Overview

```
BRANCH DEVELOP
  ↓
  └─→ Commit pushed to develop
      ↓
      ├─→ CI Workflow: ci-develop.yml
      │   ├─ Test Ventas API (Maven + Tests)
      │   ├─ Test Despacho API (Maven + Tests)
      │   ├─ Test Frontend (ESLint + Build)
      │   ├─ Build Docker Images (no push)
      │   └─ Report Results ✓
      │
      └─→ PR to Main (Manual or Auto)
          ↓

BRANCH MAIN
  ↓
  └─→ Pull Request Opened/Updated
      ├─→ CD Workflow: cd-deploy.yml (PLAN ONLY)
      │   ├─ Build Docker Images
      │   ├─ Push to AWS ECR
      │   ├─ Run Terraform Plan
      │   └─ Comment Plan in PR
      │
      ↓ (After PR Review & Merge)
      │
  └─→ Push to Main
      ├─→ CD Workflow: cd-deploy.yml (APPLY)
      │   ├─ Build Docker Images
      │   ├─ Push to AWS ECR
      │   ├─ Run Terraform Apply
      │   ├─ Update Infrastructure
      │   └─ Output URLs & Endpoints
      │
      └─→ ✅ Application Deployed to AWS
```

## 📋 Step-by-Step Setup

### 1️⃣ Initial GitHub Secrets Configuration

Go to: **Settings → Secrets and variables → Actions**

Add these secrets:

#### AWS Configuration
```
AWS_ROLE_TO_ASSUME
Value: arn:aws:iam::YOUR_ACCOUNT_ID:role/github-actions-terraform
```

#### Terraform Backend
```
TF_STATE_BUCKET
Value: innovatech-terraform-state-YOUR_ACCOUNT_ID

TF_STATE_DYNAMODB
Value: innovatech-terraform-locks
```

#### Frontend Environment Variables
```
VITE_API_URL_VENTAS
Value: https://your-domain.com/api/ventas

VITE_API_URL_DESPACHOS
Value: https://your-domain.com/api/despachos
```

#### Database Password (optional, can be set in terraform.tfvars)
```
DB_PASSWORD
Value: YourSecurePassword123!
```

### 2️⃣ AWS Setup

#### Create IAM OIDC Provider (once per account)

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

#### Create IAM Role for GitHub Actions

```bash
# Set your variables
GITHUB_ORG="your-github-org"
GITHUB_REPO="proyectofullstack2"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create the role
aws iam create-role \
  --role-name github-actions-terraform \
  --assume-role-policy-document "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [
      {
        \"Effect\": \"Allow\",
        \"Principal\": {
          \"Federated\": \"arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com\"
        },
        \"Action\": \"sts:AssumeRoleWithWebIdentity\",
        \"Condition\": {
          \"StringEquals\": {
            \"token.actions.githubusercontent.com:aud\": \"sts.amazonaws.com\"
          },
          \"StringLike\": {
            \"token.actions.githubusercontent.com:sub\": \"repo:${GITHUB_ORG}/${GITHUB_REPO}:*\"
          }
        }
      }
    ]
  }"

# Attach AdministratorAccess policy (or create more restrictive policy)
aws iam attach-role-policy \
  --role-name github-actions-terraform \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

#### Create S3 Backend for Terraform State

```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="innovatech-terraform-state-${AWS_ACCOUNT_ID}"

# Create S3 bucket
aws s3api create-bucket \
  --bucket ${BUCKET_NAME} \
  --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket ${BUCKET_NAME} \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket ${BUCKET_NAME} \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket ${BUCKET_NAME} \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

#### Create DynamoDB Table for State Locking

```bash
aws dynamodb create-table \
  --table-name innovatech-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1
```

### 3️⃣ Configure Local Environment (for testing)

```bash
cd terraform

# Copy variables template
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
nano terraform.tfvars
```

**Sample terraform.tfvars:**
```hcl
aws_region = "us-east-1"
project_name = "innovatech"
environment = "production"

ventas_api_image = "YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech/ventas-api:latest"
despacho_api_image = "YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech/despacho-api:latest"
frontend_image = "YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech/frontend:latest"

db_password = "YourSecurePassword123!"

ecs_desired_count = 2
enable_autoscaling = true
```

### 4️⃣ Initialize Terraform Backend

```bash
cd terraform

terraform init \
  -backend-config="bucket=innovatech-terraform-state-${AWS_ACCOUNT_ID}" \
  -backend-config="key=main/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="encrypt=true" \
  -backend-config="dynamodb_table=innovatech-terraform-locks"
```

## 🚀 Development Workflow

### For Frontend/Backend Developers

1. **Create feature branch from develop:**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/my-feature
   ```

2. **Make changes and commit:**
   ```bash
   git add .
   git commit -m "feat: describe your changes"
   git push origin feature/my-feature
   ```

3. **CI runs automatically** (tests + build checks)
   - Tests run for Ventas API, Despacho API, and Frontend
   - Docker images are built (not pushed)
   - Reports are available in GitHub Actions

4. **Create Pull Request to develop:**
   - Navigate to GitHub and create PR
   - CI results shown on PR
   - Get reviews from team

5. **Merge to develop:**
   - After approval, merge PR
   - CI runs again on develop

### For DevOps/Release Manager

1. **When ready for production, create PR from develop → main:**
   ```bash
   git checkout main
   git pull origin main
   git merge develop
   git push origin main
   ```
   Or create PR through GitHub UI

2. **CD workflow runs (Plan stage):**
   - Docker images built and pushed to AWS ECR
   - Terraform plan generated
   - Plan commented on PR for review

3. **Review Infrastructure Changes:**
   - Check Terraform plan in PR comments
   - Verify ECR images pushed successfully

4. **Merge PR to main:**
   - After approval, merge PR

5. **CD workflow runs (Apply stage):**
   - Terraform applies changes
   - Infrastructure updated
   - New services deployed
   - Output URLs in workflow summary

## 📊 Monitoring & Logs

### GitHub Actions Logs
1. Go to **Actions** tab
2. Select workflow run
3. Click job to see logs

### AWS CloudWatch Logs
```bash
# View ECS logs
aws logs tail /ecs/innovatech --follow

# View specific service
aws logs tail /ecs/innovatech --follow --log-stream-names ventas-api
```

### Check Deployed Resources

```bash
# Get ALB URL
aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?LoadBalancerName=='innovatech-alb'].DNSName" \
  --output text

# Check ECS services
aws ecs describe-services \
  --cluster innovatech-cluster \
  --services innovatech-ventas-api-service innovatech-despacho-api-service innovatech-frontend-service

# Get RDS endpoint
aws rds describe-db-instances \
  --db-instance-identifier innovatech-mysql \
  --query "DBInstances[0].Endpoint"
```

## 🔒 Security Best Practices

1. ✅ **Secrets**: Database password stored in AWS Secrets Manager
2. ✅ **OIDC**: GitHub Actions uses OIDC, no long-lived AWS keys
3. ✅ **Private Network**: RDS and ECS tasks in private subnets
4. ✅ **Encryption**: S3 state file encrypted, RDS encryption enabled
5. ✅ **Access Control**: ALB only exposed to public internet

## 🐛 Troubleshooting

### CI Tests Failing

```bash
# Run tests locally (develop branch)
cd back-Ventas_SpringBoot/Springboot-API-REST
mvn clean test

cd back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO
mvn clean test

cd front_despacho
npm ci
npm run lint
npm run build
```

### CD Deployment Failing

1. **Check GitHub Actions logs** for specific error
2. **Verify AWS credentials** in secrets
3. **Check Terraform syntax:**
   ```bash
   cd terraform
   terraform validate
   ```
4. **Check AWS resources exist:**
   ```bash
   aws s3 ls innovatech-terraform-state-*
   aws dynamodb list-tables | grep terraform-locks
   ```

### Application Not Accessible

```bash
# Check ALB health
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:...

# Check ECS task status
aws ecs describe-tasks \
  --cluster innovatech-cluster \
  --tasks task-arn

# View application logs
aws logs tail /ecs/innovatech --follow
```

## 📞 Support

For issues or questions:
1. Check CloudWatch logs first
2. Review GitHub Actions output
3. Check AWS Management Console for resource status
4. Consult Terraform documentation
