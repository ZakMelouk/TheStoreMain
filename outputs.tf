output "bastion_public_ip" {
  description = "Elastic IP address of the Bastion Host"
  value       = aws_eip.bastion_eip.public_ip
}


output "orders_rds_endpoint" {
  description = "Endpoint for Orders PostgreSQL"
  value       = aws_db_instance.orders.address
}

output "orders_rds_port" {
  description = "Port for Orders PostgreSQL"
  value       = aws_db_instance.orders.port
}
output "catalog_db_name" {
  description = "DB name for Catalog"
  value       = var.catalog_db_name
}

output "orders_db_secret_arn" {
  description = "ARN of the Secrets Manager secret for Orders DB credentials"
  value       = aws_secretsmanager_secret.orders_db_secret.arn
}
output "catalog_rds_endpoint" {
  description = "Endpoint for Catalog MySQL"
  value       = aws_db_instance.catalog.address
}

output "catalog_rds_port" {
  description = "Port for Catalog MySQL"
  value       = aws_db_instance.catalog.port
}

output "catalog_db_secret_arn" {
  description = "ARN of the Secrets Manager secret for Catalog DB credentials"
  value       = aws_secretsmanager_secret.catalog_db_secret.arn
}

output "redis_endpoint" {
  description = "Primary endpoint for Checkout Redis"
  value       = aws_elasticache_cluster.checkout.cache_nodes[0].address
}

output "redis_port" {
  description = "Port for Checkout Redis"
  value       = aws_elasticache_cluster.checkout.port
}
output "cart_dynamodb_table_name" {
  description = "Name of the DynamoDB table for Cart service"
  value       = aws_dynamodb_table.cart.name
}
output "dynamodb_vpc_endpoint_id" {
  description = "ID of the VPC Endpoint for DynamoDB"
  value       = aws_vpc_endpoint.dynamodb.id
}
output "vpc_id" {
  description = "Main VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "catalog_secret_arn" {
  value       = aws_secretsmanager_secret.catalog_db_secret.arn
  description = "ARN du secret Catalog"
}
output "k8s_master_private_ip" {
  description = "Private IP of the Kubernetes master node"
  value       = aws_instance.k8s_master.private_ip
}

output "k8s_worker_private_ips" {
  description = "Private IPs of the Kubernetes worker nodes"
  value       = [for w in aws_instance.k8s_worker : w.private_ip]
}

output "catalog_db_username" {
  description = "Master username for Catalog"
  value       = var.catalog_db_username
}


