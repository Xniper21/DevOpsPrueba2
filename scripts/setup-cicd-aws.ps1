# CI/CD Setup Script for Windows PowerShell
# This script sets up all the necessary AWS resources for GitHub Actions CI/CD deployment

param(
    [string]$GitHubOrg = "your-github-org",
    [string]$GitHubRepo = "proyectofullstack2",
    [string]$AwsRegion = "us-east-1",
    [string]$ProjectName = "innovatech"
)

# Colors
$Green = "`e[32m"
$Red = "`e[31m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Reset = "`e[0m"

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "$Blue================================================$Reset"
    Write-Host "$Blue$Message$Reset"
    Write-Host "$Blue================================================$Reset`n"
}

function Write-Success {
    param([string]$Message)
    Write-Host "$Green✓ $Message$Reset"
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "$Red✗ $Message$Reset"
}

function Write-Info {
    param([string]$Message)
    Write-Host "$Yellow$Message$Reset"
}

# Check prerequisites
function Check-Prerequisites {
    Write-Header "Checking Prerequisites"
    
    # Check AWS CLI
    try {
        aws --version | Out-Null
        Write-Success "AWS CLI found"
    }
    catch {
        Write-Error-Custom "AWS CLI is not installed or not in PATH"
        Write-Info "Download from: https://aws.amazon.com/cli/"
        exit 1
    }
    
    # Check AWS credentials
    try {
        aws sts get-caller-identity | Out-Null
        Write-Success "AWS credentials configured"
    }
    catch {
        Write-Error-Custom "AWS credentials not configured"
        Write-Info "Run: aws configure"
        exit 1
    }
}

# Get AWS Account ID
function Get-AccountId {
    return (aws sts get-caller-identity --query Account --output text)
}

# Step 1: Create OIDC Provider
function Setup-OIDCProvider {
    Write-Header "Step 1: Setting up GitHub OIDC Provider"
    
    $AccountId = Get-AccountId
    
    try {
        aws iam get-open-id-connect-provider `
            --open-id-connect-provider-arn "arn:aws:iam::${AccountId}:oidc-provider/token.actions.githubusercontent.com" `
            --region $AwsRegion 2>&1 | Out-Null
        
        Write-Success "OIDC Provider already exists"
    }
    catch {
        Write-Info "Creating OIDC Provider..."
        aws iam create-open-id-connect-provider `
            --url https://token.actions.githubusercontent.com `
            --client-id-list sts.amazonaws.com `
            --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 `
            --region $AwsRegion | Out-Null
        
        Write-Success "OIDC Provider created"
    }
}

# Step 2: Create IAM Role
function Setup-IAMRole {
    Write-Header "Step 2: Setting up IAM Role for GitHub Actions"
    
    $AccountId = Get-AccountId
    $RoleName = "github-actions-terraform"
    
    # Check if role exists
    try {
        aws iam get-role --role-name $RoleName 2>&1 | Out-Null
        Write-Success "IAM Role already exists"
    }
    catch {
        Write-Info "Creating IAM Role..."
        
        $TrustPolicy = @{
            Version = "2012-10-17"
            Statement = @(
                @{
                    Effect = "Allow"
                    Principal = @{
                        Federated = "arn:aws:iam::${AccountId}:oidc-provider/token.actions.githubusercontent.com"
                    }
                    Action = "sts:AssumeRoleWithWebIdentity"
                    Condition = @{
                        StringEquals = @{
                            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
                        }
                        StringLike = @{
                            "token.actions.githubusercontent.com:sub" = "repo:${GitHubOrg}/${GitHubRepo}:*"
                        }
                    }
                }
            )
        } | ConvertTo-Json -Depth 10
        
        $TrustPolicyFile = [System.IO.Path]::GetTempFileName()
        $TrustPolicy | Out-File -FilePath $TrustPolicyFile -Encoding UTF8
        
        aws iam create-role `
            --role-name $RoleName `
            --assume-role-policy-document (Get-Content $TrustPolicyFile -Raw) `
            --region $AwsRegion | Out-Null
        
        Remove-Item $TrustPolicyFile
        Write-Success "IAM Role created"
    }
    
    # Attach policy
    Write-Info "Attaching AdministratorAccess policy..."
    aws iam attach-role-policy `
        --role-name $RoleName `
        --policy-arn arn:aws:iam::aws:policy/AdministratorAccess | Out-Null
    
    Write-Success "Policy attached"
}

# Step 3: Create S3 Backend
function Setup-S3Backend {
    Write-Header "Step 3: Setting up S3 Backend for Terraform"
    
    $AccountId = Get-AccountId
    $BucketName = "${ProjectName}-terraform-state-${AccountId}"
    
    # Check if bucket exists
    try {
        aws s3api head-bucket --bucket $BucketName 2>&1 | Out-Null
        Write-Success "S3 bucket already exists: $BucketName"
    }
    catch {
        Write-Info "Creating S3 bucket: $BucketName"
        aws s3api create-bucket `
            --bucket $BucketName `
            --region $AwsRegion | Out-Null
        
        Write-Success "S3 bucket created"
    }
    
    # Enable versioning
    Write-Info "Enabling versioning..."
    $VersioningConfig = @{
        Status = "Enabled"
    } | ConvertTo-Json
    
    aws s3api put-bucket-versioning `
        --bucket $BucketName `
        --versioning-configuration Status=Enabled | Out-Null
    
    Write-Success "Versioning enabled"
    
    # Enable encryption
    Write-Info "Enabling server-side encryption..."
    aws s3api put-bucket-encryption `
        --bucket $BucketName `
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }' | Out-Null
    
    Write-Success "Encryption enabled"
    
    # Block public access
    Write-Info "Blocking public access..."
    aws s3api put-public-access-block `
        --bucket $BucketName `
        --public-access-block-configuration `
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" | Out-Null
    
    Write-Success "Public access blocked"
}

# Step 4: Create DynamoDB Table
function Setup-DynamoDBTable {
    Write-Header "Step 4: Setting up DynamoDB Table for State Locking"
    
    $TableName = "${ProjectName}-terraform-locks"
    
    try {
        aws dynamodb describe-table `
            --table-name $TableName `
            --region $AwsRegion 2>&1 | Out-Null
        
        Write-Success "DynamoDB table already exists: $TableName"
    }
    catch {
        Write-Info "Creating DynamoDB table: $TableName"
        aws dynamodb create-table `
            --table-name $TableName `
            --attribute-definitions AttributeName=LockID,AttributeType=S `
            --key-schema AttributeName=LockID,KeyType=HASH `
            --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 `
            --region $AwsRegion | Out-Null
        
        Write-Success "DynamoDB table created"
    }
}

# Output Configuration
function Output-Configuration {
    Write-Header "Configuration Summary"
    
    $AccountId = Get-AccountId
    $BucketName = "${ProjectName}-terraform-state-${AccountId}"
    $TableName = "${ProjectName}-terraform-locks"
    
    Write-Host "${Blue}AWS Configuration:${Reset}"
    Write-Host "  Account ID: $Green$AccountId$Reset"
    Write-Host "  Region: $Green$AwsRegion$Reset"
    Write-Host "  OIDC Provider: $Green`arn:aws:iam::${AccountId}:oidc-provider/token.actions.githubusercontent.com$Reset"
    Write-Host "  IAM Role: $Green`github-actions-terraform$Reset"
    Write-Host "  IAM Role ARN: $Green`arn:aws:iam::${AccountId}:role/github-actions-terraform$Reset"
    
    Write-Host ""
    Write-Host "${Blue}Terraform Backend Configuration:${Reset}"
    Write-Host "  S3 Bucket: $Green$BucketName$Reset"
    Write-Host "  DynamoDB Table: $Green$TableName$Reset"
    
    Write-Host ""
    Write-Host "${Yellow}GitHub Secrets to Add:${Reset}"
    Write-Host ""
    Write-Host "1. AWS_ROLE_TO_ASSUME"
    Write-Host "   Value: arn:aws:iam::${AccountId}:role/github-actions-terraform"
    Write-Host ""
    Write-Host "2. TF_STATE_BUCKET"
    Write-Host "   Value: $BucketName"
    Write-Host ""
    Write-Host "3. TF_STATE_DYNAMODB"
    Write-Host "   Value: $TableName"
    Write-Host ""
    Write-Host "4. VITE_API_URL_VENTAS (Optional)"
    Write-Host "   Value: https://your-domain/api/ventas"
    Write-Host ""
    Write-Host "5. VITE_API_URL_DESPACHOS (Optional)"
    Write-Host "   Value: https://your-domain/api/despachos"
}

# Main execution
function Main {
    Write-Host ""
    Write-Host "$Blue╔════════════════════════════════════════════════╗$Reset"
    Write-Host "$Blue║   AWS CI/CD Infrastructure Setup Script      ║$Reset"
    Write-Host "$Blue║   Project: $ProjectName                        ║$Reset"
    Write-Host "$Blue╚════════════════════════════════════════════════╝$Reset"
    Write-Host ""
    
    Write-Info "This script will set up AWS infrastructure for GitHub Actions CI/CD"
    Write-Info "AWS Region: $AwsRegion"
    Write-Info "GitHub Organization: $GitHubOrg"
    Write-Info "GitHub Repository: $GitHubRepo"
    Write-Host ""
    
    $Continue = Read-Host "Do you want to proceed? (yes/no)"
    if ($Continue -ne "yes" -and $Continue -ne "y") {
        Write-Error-Custom "Setup cancelled"
        exit 0
    }
    
    Check-Prerequisites
    Setup-OIDCProvider
    Setup-IAMRole
    Setup-S3Backend
    Setup-DynamoDBTable
    Output-Configuration
    
    Write-Header "Setup Complete! ✓"
    Write-Host "$Green`All AWS resources have been created successfully!$Reset"
    Write-Host ""
    Write-Host "${Yellow}Next steps:${Reset}"
    Write-Host "1. Add the GitHub Secrets shown above to your repository"
    Write-Host "2. Read: terraform/README.md for Terraform setup instructions"
    Write-Host "3. Push changes to develop branch to trigger CI workflow"
    Write-Host "4. Create PR to main branch to trigger CD workflow"
}

Main
