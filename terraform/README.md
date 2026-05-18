# Terraform Setup and Deployment Guide for Innovatech FullStack

## 📋 Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** configured with credentials
3. **Terraform** >= 1.0 installed
4. **S3 Bucket** for Terraform state (with DynamoDB table for locking)
5. **GitHub Secrets** configured (see below)
6. **IAM Role** for GitHub Actions OIDC federation

## 🔧 Initial Setup

### 1. Create S3 Bucket for Terraform State

```bash
aws s3api create-bucket \
  --bucket innovatech-terraform-state-$(aws sts get-caller-identity --query Account --output text) \
  --region us-east-1 \
  --acl private

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket innovatech-terraform-state-$(aws sts get-caller-identity --query Account --output text) \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket innovatech-terraform-state-$(aws sts get-caller-identity --query Account --output text) \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
```

### 2. Create DynamoDB Table for State Locking

```bash
aws dynamodb create-table \
  --table-name innovatech-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1
```

### 3. GitHub Actions OIDC Provider Setup

```bash
# Create IAM OIDC Identity Provider for GitHub
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com

# Create IAM Role for GitHub Actions
aws iam create-role \
  --role-name github-actions-terraform \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
          "StringEquals": {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
          },
          "StringLike": {
            "token.actions.githubusercontent.com:sub": "repo:YOUR_ORG/proyectofullstack2:*"
          }
        }
      }
    ]
  }'

# Attach policies to the role
aws iam attach-role-policy \
  --role-name github-actions-terraform \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

## 📝 Configure GitHub Secrets

Add the following secrets to your GitHub repository:

```
AWS_ROLE_TO_ASSUME=arn:aws:iam::ACCOUNT_ID:role/github-actions-terraform
TF_STATE_BUCKET=innovatech-terraform-state-ACCOUNT_ID
TF_STATE_DYNAMODB=innovatech-terraform-locks
VITE_API_URL_VENTAS=https://your-domain/api/ventas
VITE_API_URL_DESPACHOS=https://your-domain/api/despachos
```

## 🚀 Local Development / Testing

### 1. Copy and Configure Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 2. Initialize Terraform

```bash
terraform init \
  -backend-config="bucket=innovatech-terraform-state-ACCOUNT_ID" \
  -backend-config="key=main/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="encrypt=true" \
  -backend-config="dynamodb_table=innovatech-terraform-locks"
```

### 3. Plan Deployment

```bash
terraform plan \
  -var="ventas_api_image=YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech/ventas-api:latest" \
  -var="despacho_api_image=YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech/despacho-api:latest" \
  -var="frontend_image=YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech/frontend:latest" \
  -var="environment=production"
```

### 4. Apply Deployment

```bash
terraform apply \
  -var="ventas_api_image=YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech/ventas-api:latest" \
  -var="despacho_api_image=YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech/despacho-api:latest" \
  -var="frontend_image=YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech/frontend:latest" \
  -var="environment=production"
```

### 5. Get Outputs

```bash
terraform output
terraform output alb_dns_name
terraform output frontend_url
```

## 📊 Infrastructure Components

### VPC and Networking
- **VPC**: 10.0.0.0/16
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24 (for ALB)
- **Private Subnets**: 10.0.11.0/24, 10.0.12.0/24 (for ECS/RDS)
- **NAT Gateway**: For outbound traffic from private subnets
- **Internet Gateway**: For inbound traffic to ALB

### RDS Database
- **Engine**: MySQL 8.0.35
- **Instance Type**: db.t3.micro (configurable)
- **Storage**: 20 GB (configurable)
- **Backup**: 7 days retention (30 days for production)
- **Multi-AZ**: Enabled in production

### ECS Services
- **Cluster**: With container insights enabled
- **Services**:
  - Ventas API (Spring Boot)
  - Despacho API (Spring Boot)
  - Frontend (React + Nginx)
- **Launch Type**: Fargate
- **Desired Count**: 2 tasks per service
- **Auto Scaling**: CPU-based (70% target)

### Load Balancer
- **Type**: Application Load Balancer (ALB)
- **Routing**:
  - `/api/ventas/*` → Ventas API
  - `/api/despachos/*` → Despacho API
  - `/` → Frontend

## 🔒 Security

- **VPC**: Private subnets for databases and applications
- **Security Groups**: Restricted ingress/egress rules
- **RDS**: Encryption enabled, not publicly accessible
- **Secrets Manager**: Database password stored securely
- **IAM**: Minimal permissions for ECS tasks

## 📈 Scaling

### Vertical Scaling
Modify `ecs_task_cpu` and `ecs_task_memory` in `terraform.tfvars`:
```
ecs_task_cpu = "512"
ecs_task_memory = "1024"
```

### Horizontal Scaling
- **Desired Count**: Modify `ecs_desired_count`
- **Auto Scaling**: Controlled by `enable_autoscaling` (targets 70% CPU)
- **Max Capacity**: 4 tasks per service

## 🧹 Cleanup

```bash
terraform destroy \
  -var="ventas_api_image=YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech/ventas-api:latest" \
  -var="despacho_api_image=YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech/despacho-api:latest" \
  -var="frontend_image=YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/innovatech/frontend:latest" \
  -var="environment=production"
```

## 📚 Resources

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS](https://docs.aws.amazon.com/ecs/)
- [AWS RDS](https://docs.aws.amazon.com/rds/)
- [AWS VPC](https://docs.aws.amazon.com/vpc/)

## 🐛 Troubleshooting

### State Lock Issues
```bash
terraform force-unlock LOCK_ID
```

### RDS Connection Issues
```bash
# Check security group rules
aws ec2 describe-security-groups --query "SecurityGroups[?GroupName=='innovatech-rds-sg']"

# Check RDS status
aws rds describe-db-instances --db-instance-identifier innovatech-mysql
```

### ECS Task Issues
```bash
# Check task logs
aws logs tail /ecs/innovatech --follow

# Describe service
aws ecs describe-services --cluster innovatech-cluster --services innovatech-ventas-api-service
```
