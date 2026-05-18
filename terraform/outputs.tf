output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.main.arn
}

output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.mysql.endpoint
  sensitive   = true
}

output "rds_address" {
  description = "RDS database address"
  value       = aws_db_instance.mysql.address
}

output "rds_port" {
  description = "RDS database port"
  value       = aws_db_instance.mysql.port
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "ventas_api_service_name" {
  description = "Ventas API service name"
  value       = aws_ecs_service.ventas_api.name
}

output "despacho_api_service_name" {
  description = "Despacho API service name"
  value       = aws_ecs_service.despacho_api.name
}

output "frontend_service_name" {
  description = "Frontend service name"
  value       = aws_ecs_service.frontend.name
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for ECS"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "frontend_url" {
  description = "Frontend URL"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ventas_api_url" {
  description = "Ventas API URL"
  value       = "http://${aws_lb.main.dns_name}/api/ventas"
}

output "despacho_api_url" {
  description = "Despacho API URL"
  value       = "http://${aws_lb.main.dns_name}/api/despachos"
}
