#!/bin/bash

# =====================================================
# EC2 User Data Script - Runs on instance startup
# =====================================================

set -e

# Update system
yum update -y

# Install Docker
amazon-linux-extras install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Install git
yum install -y git

# Create application directory
mkdir -p /home/ec2-user/innovatech
cd /home/ec2-user/innovatech

# Clone repository (if needed)
# git clone <your-repo-url> .

# Create systemd service for docker-compose
cat > /etc/systemd/system/innovatech.service << 'EOF'
[Unit]
Description=Innovatech Docker Compose Application
Requires=docker.service
After=docker.service

[Service]
Type=simple
WorkingDirectory=/home/ec2-user/innovatech
ExecStart=/usr/local/bin/docker-compose up
ExecStop=/usr/local/bin/docker-compose down
Restart=always
RestartSec=10
User=ec2-user
Environment="PATH=/usr/local/bin:/usr/bin:/bin"

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable innovatech.service

# CloudWatch logs
yum install -y amazon-cloudwatch-agent

echo "✓ EC2 setup complete"
