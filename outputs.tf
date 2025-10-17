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
