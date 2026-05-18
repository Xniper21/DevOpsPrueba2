variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "innovatech"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "container_port" {
  description = "Port exposed by the containers"
  type        = number
  default     = 8080
}

variable "app_version" {
  description = "Application version"
  type        = string
  default     = "latest"
}

# ==================== CONTAINER IMAGE VARIABLES ====================
variable "ventas_api_image" {
  description = "Docker image URI for Ventas API (ECR)"
  type        = string
}

variable "despacho_api_image" {
  description = "Docker image URI for Despacho API (ECR)"
  type        = string
}

variable "frontend_image" {
  description = "Docker image URI for Frontend (ECR)"
  type        = string
}

# ==================== DATABASE VARIABLES ====================
variable "db_engine_version" {
  description = "MySQL database engine version"
  type        = string
  default     = "8.0.35"
}

variable "db_instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "innovatech"
  sensitive   = true
}

variable "db_password" {
  description = "Master password for RDS"
  type        = string
  sensitive   = true
}

# ==================== ECS VARIABLES ====================
variable "ecs_task_cpu" {
  description = "CPU units for ECS task"
  type        = string
  default     = "256"
}

variable "ecs_task_memory" {
  description = "Memory for ECS task in MB"
  type        = string
  default     = "512"
}

variable "ecs_desired_count" {
  description = "Desired number of running tasks"
  type        = number
  default     = 2
}

variable "enable_autoscaling" {
  description = "Enable auto-scaling for ECS services"
  type        = bool
  default     = true
}

# ==================== TAGS ====================
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Terraform = "true"
  }
}
