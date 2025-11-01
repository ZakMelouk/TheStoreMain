###############################################
# RDS MySQL for Catalog (private)
###############################################

# 1️⃣ DB Subnet Group
resource "aws_db_subnet_group" "catalog_subnets" {
  name       = "catalog-db-subnets"
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name = "catalog-db-subnets"
  }
}

# 2️⃣ Parameter Group (optional)
resource "aws_db_parameter_group" "catalog_pg" {
  name        = "catalog-mysql-params"
  family      = "mysql8.0" # Version du moteur
  description = "Parameter group for Catalog MySQL"

  # Exemple de paramètre optionnel
  # parameter {
  #   name  = "slow_query_log"
  #   value = "1"
  # }
}

# 3️⃣ Secrets (username/password) via Secrets Manager
resource "random_password" "catalog_password" {
  length  = 20
  special = true
  override_special = "!#$%^&*()_+=-[]{}:;,.?~" # pas de /, @, "

}

resource "aws_secretsmanager_secret" "catalog_db_secret" {
  name        = "catalog-db-credentials"
  description = "Credentials for Catalog RDS (MySQL)"
}

resource "aws_secretsmanager_secret_version" "catalog_db_secret_v" {
  secret_id     = aws_secretsmanager_secret.catalog_db_secret.id
  secret_string = jsonencode({
    username = var.catalog_db_username
    password = random_password.catalog_password.result
    engine   = "mysql"
    host     = null
    port     = 3306
    dbname   = var.catalog_db_name
  })
}

# 4️⃣ RDS Instance (MySQL)
resource "aws_db_instance" "catalog" {
  identifier              = "catalog-mysql"
  engine                  = "mysql"
  engine_version          = var.catalog_engine_version
  instance_class          = var.catalog_instance_class
  allocated_storage       = var.catalog_allocated_storage
  max_allocated_storage   = var.catalog_max_allocated_storage
  storage_encrypted       = true

  db_subnet_group_name    = aws_db_subnet_group.catalog_subnets.name
  vpc_security_group_ids  = [aws_security_group.sg_db.id]
  publicly_accessible     = false     # reste privé
  multi_az                = false     # POC : simple AZ

  username                = var.catalog_db_username
  password                = random_password.catalog_password.result

  db_name                 = var.catalog_db_name
  port                    = 3306
  parameter_group_name    = aws_db_parameter_group.catalog_pg.name

  # Options simplifiées pour la démo
  auto_minor_version_upgrade = true
  backup_retention_period    = 1
  deletion_protection        = false
  skip_final_snapshot        = true

  tags = {
    Name        = "catalog-mysql"
    Project     = "the-store"
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.igw]
}

