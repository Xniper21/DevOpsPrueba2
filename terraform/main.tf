# ==================== NETWORKING ====================
# (VPC, Subnets, Route Tables, and NAT Gateway remain unchanged)

# ==================== SECURITY GROUPS ====================
# (ALB, ECS Tasks, and RDS Security Groups remain unchanged)

# ==================== RDS DATABASE ====================
resource "aws_db_subnet_group" "default" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

resource "aws_db_instance" "mysql" {
  identifier            = "${var.project_name}-mysql"
  engine                = "mysql"
  engine_version        = var.db_engine_version
  instance_class        = "db.t3.micro" # AWS Academy Free Tier Friendly
  allocated_storage     = var.db_allocated_storage
  
  db_name  = "innovatechdb"
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  skip_final_snapshot    = true # Forced for Academy labs to prevent deletion hangs
  storage_encrypted      = false # Avoid KMS policy errors in lab environments
  publicly_accessible    = false
  multi_az               = false # FORCED FALSE: AWS Academy accounts don't allow Multi-AZ

  tags = {
    Name = "${var.project_name}-mysql"
  }
}

# ==================== ECR REPOSITORIES ====================
data "aws_ecr_repository" "ventas_api" { name = "${var.project_name}/ventas-api" }
data "aws_ecr_repository" "despacho_api" { name = "${var.project_name}/despacho-api" }
data "aws_ecr_repository" "frontend" { name = "${var.project_name}/frontend" }

# ==================== ECS CLUSTER ====================
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE"]
}

# ==================== CLOUDWATCH LOG GROUP ====================
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 3
}

# !!! IAM ROLE CREATION REMOVED !!!
# The ecs_task_execution_role and ecs_task_role resources are deleted 
# because AWS Academy students do not have iam:CreateRole authorizations.

# ==================== ALB ====================
# (ALB, Target Groups, Listeners, and Routing Rules remain unchanged)

# ==================== ECS TASK DEFINITIONS ====================

# We will declare a local variable or input variable matching the pre-existing LabRole ARN
# Format: "arn:aws:iam::<ACCOUNT_ID>:role/LabRole"
# You can find your Account ID via the AWS Academy console top right window or console terminal.

variable "aws_academy_lab_role_arn" {
  description = "The pre-existing LabRole ARN provided by AWS Academy"
  type        = string
  default     = "arn:aws:iam::123456789012:role/LabRole" # <-- Replace with your real lab account ID
}

# Ventas API Task Definition
resource "aws_ecs_task_definition" "ventas_api" {
  family                   = "${var.project_name}-ventas-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = var.aws_academy_lab_role_arn # Using Learner Lab Prebuilt Role
  task_role_arn            = var.aws_academy_lab_role_arn # Using Learner Lab Prebuilt Role

  container_definitions = jsonencode([
    {
      name      = "ventas-api"
      image     = var.ventas_api_image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name  = "DB_ENDPOINT", value = aws_db_instance.mysql.endpoint },
        { name  = "DB_NAME",     value = aws_db_instance.mysql.db_name },
        { name  = "DB_USERNAME", value = var.db_username },
        { name  = "DB_PASSWORD", value = var.db_password }, # Plaintext variable injector for Academy bypass
        { name  = "JAVA_OPTS",   value = "-Xms128m -Xmx256m" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ventas-api"
        }
      }
    }
  ])
}

# Despacho API Task Definition
resource "aws_ecs_task_definition" "despacho_api" {
  family                   = "${var.project_name}-despacho-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = var.aws_academy_lab_role_arn # Using Learner Lab Prebuilt Role
  task_role_arn            = var.aws_academy_lab_role_arn # Using Learner Lab Prebuilt Role

  container_definitions = jsonencode([
    {
      name      = "despacho-api"
      image     = var.despacho_api_image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name  = "DB_ENDPOINT", value = aws_db_instance.mysql.endpoint },
        { name  = "DB_NAME",     value = aws_db_instance.mysql.db_name },
        { name  = "DB_USERNAME", value = var.db_username },
        { name  = "DB_PASSWORD", value = var.db_password }, # Plaintext variable injector for Academy bypass
        { name  = "JAVA_OPTS",   value = "-Xms128m -Xmx256m" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "despacho-api"
        }
      }
    }
  ])
}

# Frontend Task Definition
resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.project_name}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.aws_academy_lab_role_arn # Using Learner Lab Prebuilt Role
  task_role_arn            = var.aws_academy_lab_role_arn # Using Learner Lab Prebuilt Role

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = var.frontend_image
      essential = true
      portMappings = [{ containerPort = 80, hostPort = 80, protocol = "tcp" }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "frontend"
        }
      }
    }
  ])
}

# ==================== ECS SERVICES ====================
# (Services can stay the same, but remove auto-scaling policies to conserve student lab resource limits)
