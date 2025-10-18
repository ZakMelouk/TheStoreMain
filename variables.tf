variable "ssh_public_key" {
  description = "Public SSH key for the Bastion host (pass at runtime)"
  type        = string
}

# Contexte env (pour tags)
variable "environment" {
  description = "Environment name (e.g., dev, poc, prod)"
  type        = string
  default     = "poc"
}

# Orders (Postgres)
variable "orders_db_name" {
  description = "Database name for Orders service"
  type        = string
  default     = "ordersdb"
}

variable "orders_db_username" {
  description = "Master username for Orders DB"
  type        = string
  default     = "orders_admin"
}

variable "orders_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "14.12"
}

variable "orders_instance_class" {
  description = "Instance class for Orders DB"
  type        = string
  default     = "db.t3.micro"
}

variable "orders_allocated_storage" {
  description = "Initial storage (GB) for Orders DB"
  type        = number
  default     = 20
}

variable "orders_max_allocated_storage" {
  description = "Max autoscaling storage (GB) for Orders DB"
  type        = number
  default     = 100
}
# MySQL (Catalog)
variable "catalog_db_name" {
  description = "Database name for Catalog service"
  type        = string
  default     = "catalogdb"
}

variable "catalog_db_username" {
  description = "Master username for Catalog DB"
  type        = string
  default     = "catalog_admin"
}

variable "catalog_engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0"
}

variable "catalog_instance_class" {
  description = "Instance class for Catalog DB"
  type        = string
  default     = "db.t3.micro"
}

variable "catalog_allocated_storage" {
  description = "Initial storage (GB) for Catalog DB"
  type        = number
  default     = 20
}

variable "catalog_max_allocated_storage" {
  description = "Max autoscaling storage (GB) for Catalog DB"
  type        = number
  default     = 100
}
# Redis (Checkout)
variable "redis_engine_version" {
  description = "Version of Redis engine"
  type        = string
  default     = "7.1"
}

variable "redis_node_type" {
  description = "Node type for Redis cluster"
  type        = string
  default     = "cache.t3.micro"
}
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

