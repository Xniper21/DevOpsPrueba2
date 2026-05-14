#!/bin/bash

# =====================================================
# AWS ECR Setup and Push Script
# Usage: ./scripts/push-to-ecr.sh [version]
# =====================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-$(aws sts get-caller-identity --query Account --output text)}"
REGISTRY_ALIAS="innovatech"
REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
VERSION="${1:-latest}"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}AWS ECR Push Script${NC}"
echo -e "${YELLOW}========================================${NC}"
echo -e "Registry: ${GREEN}${REGISTRY}${NC}"
echo -e "Alias: ${GREEN}${REGISTRY_ALIAS}${NC}"
echo -e "Version: ${GREEN}${VERSION}${NC}"
echo -e "Region: ${GREEN}${AWS_REGION}${NC}"
echo ""

# ===== Step 1: Create ECR Repositories =====
echo -e "${YELLOW}Step 1: Creating ECR Repositories...${NC}"

for repo in ventas-api despacho-api frontend; do
    echo -n "  • Creating repository: ${repo}... "
    if aws ecr describe-repositories \
        --repository-names "${REGISTRY_ALIAS}/${repo}" \
        --region "${AWS_REGION}" 2>/dev/null; then
        echo -e "${GREEN}Already exists${NC}"
    else
        aws ecr create-repository \
            --repository-name "${REGISTRY_ALIAS}/${repo}" \
            --region "${AWS_REGION}" \
            --encryption-configuration encryptionType=AES >/dev/null
        echo -e "${GREEN}Created${NC}"
    fi
done
echo ""

# ===== Step 2: Login to ECR =====
echo -e "${YELLOW}Step 2: Logging in to ECR...${NC}"
aws ecr get-login-password --region "${AWS_REGION}" | \
    docker login --username AWS --password-stdin "${REGISTRY}"
echo -e "${GREEN}✓ Logged in successfully${NC}"
echo ""

# ===== Step 3: Build and Push Images =====
echo -e "${YELLOW}Step 3: Building and Pushing Images...${NC}"

images=(
    "ventas-api:back-Ventas_SpringBoot/Springboot-API-REST"
    "despacho-api:back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO"
    "frontend:front_despacho"
)

for image_info in "${images[@]}"; do
    IFS=':' read -r image_name image_path <<< "${image_info}"
    
    echo -e "\n  ${YELLOW}Building: ${image_name}${NC}"
    
    full_image_name="${REGISTRY}/${REGISTRY_ALIAS}/${image_name}"
    docker build -t "${full_image_name}:${VERSION}" -t "${full_image_name}:latest" "${image_path}"
    
    echo -e "  ${YELLOW}Pushing: ${image_name}${NC}"
    docker push "${full_image_name}:${VERSION}"
    docker push "${full_image_name}:latest"
    
    echo -e "  ${GREEN}✓ ${image_name} pushed${NC}"
done

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ All images pushed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Images are now available at:"
echo -e "  • ${GREEN}${REGISTRY}/${REGISTRY_ALIAS}/ventas-api:${VERSION}${NC}"
echo -e "  • ${GREEN}${REGISTRY}/${REGISTRY_ALIAS}/despacho-api:${VERSION}${NC}"
echo -e "  • ${GREEN}${REGISTRY}/${REGISTRY_ALIAS}/frontend:${VERSION}${NC}"
