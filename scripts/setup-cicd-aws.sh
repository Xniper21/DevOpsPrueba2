#!/bin/bash

##############################################################################
# AWS Infrastructure Setup Script for GitHub Actions
# This script sets up all the necessary AWS resources for CI/CD deployment
##############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="innovatech"
AWS_REGION=${AWS_REGION:-us-east-1}
GITHUB_ORG=${GITHUB_ORG:-"your-github-org"}
GITHUB_REPO=${GITHUB_REPO:-"proyectofullstack2"}

# Functions
print_header() {
    echo -e "\n${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed"
        exit 1
    fi
    print_success "AWS CLI found"
    
    if ! command -v jq &> /dev/null; then
        print_error "jq is not installed (required for parsing JSON)"
        exit 1
    fi
    print_success "jq found"
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured"
        exit 1
    fi
    print_success "AWS credentials configured"
}

# Get AWS Account ID
get_account_id() {
    aws sts get-caller-identity --query Account --output text
}

# Step 1: Create OIDC Provider
setup_oidc_provider() {
    print_header "Step 1: Setting up GitHub OIDC Provider"
    
    ACCOUNT_ID=$(get_account_id)
    
    if aws iam get-open-id-connect-provider \
        --open-id-connect-provider-arn arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com \
        &> /dev/null; then
        print_success "OIDC Provider already exists"
    else
        print_info "Creating OIDC Provider..."
        aws iam create-open-id-connect-provider \
            --url https://token.actions.githubusercontent.com \
            --client-id-list sts.amazonaws.com \
            --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
            --region ${AWS_REGION}
        print_success "OIDC Provider created"
    fi
}

# Step 2: Create IAM Role for GitHub Actions
setup_iam_role() {
    print_header "Step 2: Setting up IAM Role for GitHub Actions"
    
    ACCOUNT_ID=$(get_account_id)
    ROLE_NAME="github-actions-terraform"
    
    if aws iam get-role --role-name ${ROLE_NAME} &> /dev/null; then
        print_success "IAM Role already exists"
    else
        print_info "Creating IAM Role..."
        
        cat > /tmp/trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_ORG}/${GITHUB_REPO}:*"
        }
      }
    }
  ]
}
EOF
        
        aws iam create-role \
            --role-name ${ROLE_NAME} \
            --assume-role-policy-document file:///tmp/trust-policy.json \
            --region ${AWS_REGION}
        
        rm /tmp/trust-policy.json
        print_success "IAM Role created"
    fi
    
    # Attach policy
    print_info "Attaching AdministratorAccess policy..."
    aws iam attach-role-policy \
        --role-name ${ROLE_NAME} \
        --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
    print_success "Policy attached"
}

# Step 3: Create S3 Backend Bucket
setup_s3_backend() {
    print_header "Step 3: Setting up S3 Backend for Terraform"
    
    ACCOUNT_ID=$(get_account_id)
    BUCKET_NAME="${PROJECT_NAME}-terraform-state-${ACCOUNT_ID}"
    
    # Check if bucket exists
    if aws s3api head-bucket --bucket ${BUCKET_NAME} 2>/dev/null; then
        print_success "S3 bucket already exists: ${BUCKET_NAME}"
    else
        print_info "Creating S3 bucket: ${BUCKET_NAME}"
        aws s3api create-bucket \
            --bucket ${BUCKET_NAME} \
            --region ${AWS_REGION}
        
        # Wait for bucket to be created
        aws s3api wait bucket-exists --bucket ${BUCKET_NAME}
        print_success "S3 bucket created"
    fi
    
    # Enable versioning
    print_info "Enabling versioning..."
    aws s3api put-bucket-versioning \
        --bucket ${BUCKET_NAME} \
        --versioning-configuration Status=Enabled
    print_success "Versioning enabled"
    
    # Enable encryption
    print_info "Enabling server-side encryption..."
    aws s3api put-bucket-encryption \
        --bucket ${BUCKET_NAME} \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }'
    print_success "Encryption enabled"
    
    # Block public access
    print_info "Blocking public access..."
    aws s3api put-public-access-block \
        --bucket ${BUCKET_NAME} \
        --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    print_success "Public access blocked"
}

# Step 4: Create DynamoDB Table for State Locking
setup_dynamodb_table() {
    print_header "Step 4: Setting up DynamoDB Table for State Locking"
    
    TABLE_NAME="${PROJECT_NAME}-terraform-locks"
    
    if aws dynamodb describe-table --table-name ${TABLE_NAME} --region ${AWS_REGION} &> /dev/null; then
        print_success "DynamoDB table already exists: ${TABLE_NAME}"
    else
        print_info "Creating DynamoDB table: ${TABLE_NAME}"
        aws dynamodb create-table \
            --table-name ${TABLE_NAME} \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
            --region ${AWS_REGION}
        
        # Wait for table to be created
        aws dynamodb wait table-exists --table-name ${TABLE_NAME} --region ${AWS_REGION}
        print_success "DynamoDB table created"
    fi
}

# Step 5: Output Configuration
output_configuration() {
    print_header "Configuration Summary"
    
    ACCOUNT_ID=$(get_account_id)
    BUCKET_NAME="${PROJECT_NAME}-terraform-state-${ACCOUNT_ID}"
    TABLE_NAME="${PROJECT_NAME}-terraform-locks"
    
    echo -e "${BLUE}AWS Configuration:${NC}"
    echo -e "  Account ID: ${GREEN}${ACCOUNT_ID}${NC}"
    echo -e "  Region: ${GREEN}${AWS_REGION}${NC}"
    echo -e "  OIDC Provider: ${GREEN}arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com${NC}"
    echo -e "  IAM Role: ${GREEN}github-actions-terraform${NC}"
    echo -e "  IAM Role ARN: ${GREEN}arn:aws:iam::${ACCOUNT_ID}:role/github-actions-terraform${NC}"
    
    echo ""
    echo -e "${BLUE}Terraform Backend Configuration:${NC}"
    echo -e "  S3 Bucket: ${GREEN}${BUCKET_NAME}${NC}"
    echo -e "  DynamoDB Table: ${GREEN}${TABLE_NAME}${NC}"
    
    echo ""
    echo -e "${YELLOW}GitHub Secrets to Add:${NC}"
    echo ""
    echo "1. AWS_ROLE_TO_ASSUME"
    echo "   Value: arn:aws:iam::${ACCOUNT_ID}:role/github-actions-terraform"
    echo ""
    echo "2. TF_STATE_BUCKET"
    echo "   Value: ${BUCKET_NAME}"
    echo ""
    echo "3. TF_STATE_DYNAMODB"
    echo "   Value: ${TABLE_NAME}"
    echo ""
    echo "4. VITE_API_URL_VENTAS (Optional)"
    echo "   Value: https://your-domain/api/ventas"
    echo ""
    echo "5. VITE_API_URL_DESPACHOS (Optional)"
    echo "   Value: https://your-domain/api/despachos"
}

# Main execution
main() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════╗"
    echo "║   AWS CI/CD Infrastructure Setup Script      ║"
    echo "║   Project: ${PROJECT_NAME}                        ║"
    echo "╚════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    print_info "This script will set up AWS infrastructure for GitHub Actions CI/CD"
    print_info "AWS Region: ${AWS_REGION}"
    print_info "GitHub Organization: ${GITHUB_ORG}"
    print_info "GitHub Repository: ${GITHUB_REPO}"
    echo ""
    
    read -p "$(echo -e ${YELLOW})Do you want to proceed? (yes/no): $(echo -e ${NC})" -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        print_error "Setup cancelled"
        exit 0
    fi
    
    check_prerequisites
    setup_oidc_provider
    setup_iam_role
    setup_s3_backend
    setup_dynamodb_table
    output_configuration
    
    print_header "Setup Complete! ✓"
    echo -e "${GREEN}All AWS resources have been created successfully!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Add the GitHub Secrets shown above to your repository"
    echo "2. Run: terraform/README.md for Terraform setup instructions"
    echo "3. Push changes to develop branch to trigger CI workflow"
    echo "4. Create PR to main branch to trigger CD workflow"
}

main
