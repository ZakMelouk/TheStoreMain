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
  family      = "postgres14" # adapte si tu changes la version
  description = "Parameter group for Orders PostgreSQL"

  # Exemple de paramètre (désactivé par défaut)
  # parameter {
  #   name  = "log_min_duration_statement"
  #   value = "1000"
  # }
}

# 3) Secrets (username/password) via Secrets Manager
resource "random_password" "orders_password" {
  length           = 20
  special          = true
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
    host     = null  # sera renseigné après création si besoin
    port     = 5432
    dbname   = var.orders_db_name
  })
}

# 4) RDS Instance (PostgreSQL)
resource "aws_db_instance" "orders" {
  identifier              = "orders-postgres"
  engine                  = "postgres"
  engine_version          = var.orders_engine_version    # ex. "14.12"
  instance_class          = var.orders_instance_class    # ex. "db.t3.micro"
  allocated_storage       = var.orders_allocated_storage # ex. 20
  max_allocated_storage   = var.orders_max_allocated_storage # ex. 100
  storage_encrypted       = true

  # Networking
  db_subnet_group_name    = aws_db_subnet_group.orders_subnets.name
  vpc_security_group_ids  = [aws_security_group.sg_db.id]
  publicly_accessible     = false          # ❗ privé
  multi_az                = false          # POC : false. Prod : true

  # Auth
  username                = var.orders_db_username
  password                = random_password.orders_password.result

  # DB settings
  db_name                 = var.orders_db_name
  port                    = 5432
  parameter_group_name    = aws_db_parameter_group.orders_pg.name

  # Maintenance windows (facultatif, valeurs par défaut ok)
  auto_minor_version_upgrade = true
  backup_retention_period    = 1           # POC : minime
  deletion_protection        = false       # POC : false (destroy facile)
  skip_final_snapshot        = true        # POC : pas de snapshot à la destruction

  tags = {
    Name = "orders-postgres"
    Project = "the-store"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.igw]
}
