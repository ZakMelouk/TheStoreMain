###############################################
# ElastiCache Redis for Checkout (private)
###############################################

# 1️⃣ Subnet Group pour Redis
resource "aws_elasticache_subnet_group" "checkout_subnets" {
  name       = "checkout-redis-subnets"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name = "checkout-redis-subnets"
  }
}

# 2️⃣ Parameter Group (optionnel)
resource "aws_elasticache_parameter_group" "checkout_pg" {
  name        = "checkout-redis-params"
  family      = "redis7"
  description = "Parameter group for Checkout Redis"
}


# 4️⃣ ElastiCache Cluster (Redis)
resource "aws_elasticache_cluster" "checkout" {
  cluster_id           = "checkout-redis"
  engine               = "redis"
  engine_version       = var.redis_engine_version
  node_type            = var.redis_node_type
  num_cache_nodes      = 1
  parameter_group_name = aws_elasticache_parameter_group.checkout_pg.name
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.checkout_subnets.name
  security_group_ids   = [aws_security_group.sg_redis.id]
  apply_immediately    = true

  tags = {
    Name        = "checkout-redis"
    Project     = "the-store"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.igw]
}
