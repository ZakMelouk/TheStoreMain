###############################################
# RDS PostgreSQL for Orders (private)
###############################################

# 1) DB Subnet Group (RDS in private subnets)
resource "aws_db_subnet_group" "orders_subnets" {
  name       = "orders-db-subnets"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name = "orders-db-subnets"
  }
}

# 2) (Optional) Parameter Group (tuning)
resource "aws_db_parameter_group" "orders_pg" {
  name        = "orders-postgres-params"
  family      = "postgres14" # adjust if you change the version
  description = "Parameter group for Orders PostgreSQL"

  # Example parameter (disabled by default)
  # parameter {
  #   name  = "log_min_duration_statement"
  #   value = "1000"
  # }
}

# 3) Secrets (username/password) via Secrets Manager
resource "random_password" "orders_password" {
  length           = 20
  special          = true
  override_special = "!#$%^&*()_+=-[]{}:;,.?~" # no /, @, "
}

resource "aws_secretsmanager_secret" "orders_db_secret" {
  name        = "orders-db-credentials"
  description = "Credentials for Orders RDS (PostgreSQL)"
}

resource "aws_secretsmanager_secret_version" "orders_db_secret_v" {
  secret_id     = aws_secretsmanager_secret.orders_db_secret.id
  secret_string = jsonencode({
    username = var.orders_db_username
    password = random_password.orders_password.result
    engine   = "postgres"
    host     = null  # will be filled after creation if needed
    port     = 5432
    dbname   = var.orders_db_name
  })
}

# 4) RDS Instance (PostgreSQL)
resource "aws_db_instance" "orders" {
  identifier              = "orders-postgres"
  engine                  = "postgres"
  engine_version          = var.orders_engine_version    # e.g. "14.12"
  instance_class          = var.orders_instance_class    # e.g. "db.t3.micro"
  allocated_storage       = var.orders_allocated_storage # e.g. 20
  max_allocated_storage   = var.orders_max_allocated_storage # e.g. 100
  storage_encrypted       = true

  # Networking
  db_subnet_group_name    = aws_db_subnet_group.orders_subnets.name
  vpc_security_group_ids  = [aws_security_group.sg_db.id]
  publicly_accessible     = false          # ❗ private
  multi_az                = true          

  # Auth
  username                = var.orders_db_username
  password                = random_password.orders_password.result

  # DB settings
  db_name                 = var.orders_db_name
  port                    = 5432
  parameter_group_name    = aws_db_parameter_group.orders_pg.name

  # Maintenance windows (optional, default values are fine)
  auto_minor_version_upgrade = true
  backup_retention_period    = 1           # POC: minimal
  deletion_protection        = false       # POC: false (easy destroy)
  skip_final_snapshot        = true        # POC: no snapshot on destroy

  tags = {
    Name = "orders-postgres"
    Project = "the-store"
    Environment = var.environment
  }

}
