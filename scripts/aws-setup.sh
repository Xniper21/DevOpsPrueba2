#!/bin/bash

# =====================================================
# AWS Infrastructure Setup Script
# =====================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}======================================"
    echo -e "$1"
    echo -e "======================================${NC}"
}

print_step() {
    echo -e "${YELLOW}➜ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
INSTANCE_TYPE="${INSTANCE_TYPE:-t3.medium}"
KEY_PAIR_NAME="${KEY_PAIR_NAME:-innovatech-key}"
SECURITY_GROUP_NAME="innovatech-sg"
INSTANCE_NAME="innovatech-production"

print_header "AWS Infrastructure Setup"

# Step 1: Check AWS CLI
print_step "Checking AWS CLI..."
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI not found. Please install it first."
    exit 1
fi
print_success "AWS CLI found"

# Step 2: Create VPC (if needed)
print_step "Checking VPC..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=innovatech-vpc" \
    --query 'Vpcs[0].VpcId' --output text --region "${AWS_REGION}" 2>/dev/null || echo "")

if [ "${VPC_ID}" == "None" ] || [ -z "${VPC_ID}" ]; then
    print_step "Creating VPC..."
    VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --region "${AWS_REGION}" \
        --query 'Vpc.VpcId' --output text)
    aws ec2 create-tags --resources "${VPC_ID}" --tags "Key=Name,Value=innovatech-vpc" \
        --region "${AWS_REGION}"
    print_success "VPC created: ${VPC_ID}"
else
    print_success "VPC found: ${VPC_ID}"
fi

# Step 3: Create Subnet (if needed)
print_step "Checking Subnet..."
SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" \
    --query 'Subnets[0].SubnetId' --output text --region "${AWS_REGION}" 2>/dev/null || echo "")

if [ "${SUBNET_ID}" == "None" ] || [ -z "${SUBNET_ID}" ]; then
    print_step "Creating Subnet..."
    SUBNET_ID=$(aws ec2 create-subnet --vpc-id "${VPC_ID}" --cidr-block 10.0.1.0/24 \
        --region "${AWS_REGION}" --query 'Subnet.SubnetId' --output text)
    print_success "Subnet created: ${SUBNET_ID}"
else
    print_success "Subnet found: ${SUBNET_ID}"
fi

# Step 4: Create Security Group
print_step "Setting up Security Group..."
SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=${SECURITY_GROUP_NAME}" \
    --query 'SecurityGroups[0].GroupId' --output text --region "${AWS_REGION}" 2>/dev/null || echo "")

if [ "${SG_ID}" == "None" ] || [ -z "${SG_ID}" ]; then
    print_step "Creating Security Group..."
    SG_ID=$(aws ec2 create-security-group --group-name "${SECURITY_GROUP_NAME}" \
        --description "Security group for Innovatech" --vpc-id "${VPC_ID}" \
        --region "${AWS_REGION}" --query 'GroupId' --output text)
    
    # Add inbound rules
    aws ec2 authorize-security-group-ingress --group-id "${SG_ID}" \
        --protocol tcp --port 22 --cidr 0.0.0.0/0 --region "${AWS_REGION}"
    aws ec2 authorize-security-group-ingress --group-id "${SG_ID}" \
        --protocol tcp --port 80 --cidr 0.0.0.0/0 --region "${AWS_REGION}"
    aws ec2 authorize-security-group-ingress --group-id "${SG_ID}" \
        --protocol tcp --port 443 --cidr 0.0.0.0/0 --region "${AWS_REGION}"
    
    print_success "Security Group created: ${SG_ID}"
else
    print_success "Security Group found: ${SG_ID}"
fi

# Step 5: Create/Check Key Pair
print_step "Checking Key Pair..."
if ! aws ec2 describe-key-pairs --key-names "${KEY_PAIR_NAME}" \
    --region "${AWS_REGION}" 2>/dev/null | grep -q "KeyName"; then
    print_step "Creating Key Pair..."
    aws ec2 create-key-pair --key-name "${KEY_PAIR_NAME}" --region "${AWS_REGION}" \
        --query 'KeyMaterial' --output text > "${KEY_PAIR_NAME}.pem"
    chmod 600 "${KEY_PAIR_NAME}.pem"
    print_success "Key Pair created: ${KEY_PAIR_NAME}.pem"
else
    print_success "Key Pair already exists"
fi

# Step 6: Launch EC2 Instance
print_step "Launching EC2 Instance..."

# Get latest Amazon Linux 2 AMI
AMI_ID=$(aws ec2 describe-images --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text --region "${AWS_REGION}")

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "${AMI_ID}" \
    --instance-type "${INSTANCE_TYPE}" \
    --key-name "${KEY_PAIR_NAME}" \
    --security-group-ids "${SG_ID}" \
    --subnet-id "${SUBNET_ID}" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${INSTANCE_NAME}}]" \
    --user-data file://scripts/ec2-setup.sh \
    --region "${AWS_REGION}" \
    --query 'Instances[0].InstanceId' --output text)

print_success "EC2 Instance launched: ${INSTANCE_ID}"

# Step 7: Wait for Instance
print_step "Waiting for instance to be running..."
aws ec2 wait instance-running --instance-ids "${INSTANCE_ID}" --region "${AWS_REGION}"
print_success "Instance is running"

# Get Instance Details
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids "${INSTANCE_ID}" \
    --region "${AWS_REGION}" --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo ""
print_header "✓ Infrastructure Setup Complete!"
echo ""
echo -e "  ${BLUE}Instance Details:${NC}"
echo -e "    Instance ID: ${GREEN}${INSTANCE_ID}${NC}"
echo -e "    Public IP:   ${GREEN}${PUBLIC_IP}${NC}"
echo -e "    Key Pair:    ${GREEN}${KEY_PAIR_NAME}.pem${NC}"
echo ""
echo -e "  ${BLUE}Connect to instance:${NC}"
echo -e "    ${YELLOW}ssh -i ${KEY_PAIR_NAME}.pem ec2-user@${PUBLIC_IP}${NC}"
echo ""
echo -e "  ${BLUE}Next steps:${NC}"
echo -e "    1. Wait ~2 minutes for user data script to complete"
echo -e "    2. Configure AWS credentials: ${YELLOW}aws configure${NC}"
echo -e "    3. Push images to ECR: ${YELLOW}./scripts/push-to-ecr.sh${NC}"
echo -e "    4. Deploy to instance"
