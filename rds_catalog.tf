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
  family      = "mysql8.0"
  description = "Parameter group for Catalog MySQL"

  # Exemple param optionnel
  # parameter {
  #   name  = "slow_query_log"
  #   value = "1"
  # }
}

# 3️⃣ Secrets (username/password) via Secrets Manager
resource "random_password" "catalog_password" {
  length           = 20
  special          = true
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

# 3.b ✅ (Optionnel) policy pour un rôle spécifique (voclabs) qui peut lire le secret
data "aws_caller_identity" "current" {}

resource "aws_secretsmanager_secret_policy" "catalog_allow_voclabs" {
  secret_arn = aws_secretsmanager_secret.catalog_db_secret.arn
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "AllowVoclabsRead",
      Effect    = "Allow",
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/voclabs" },
      Action    = ["secretsmanager:DescribeSecret","secretsmanager:GetSecretValue"],
      Resource  = "*"
    }]
  })
}

# 4️⃣ RDS Instance (MySQL)
resource "aws_db_instance" "catalog" {
  identifier            = "catalog-mysql"
  engine                = "mysql"
  engine_version        = var.catalog_engine_version
  instance_class        = var.catalog_instance_class
  allocated_storage     = var.catalog_allocated_storage
  max_allocated_storage = var.catalog_max_allocated_storage
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.catalog_subnets.name
  vpc_security_group_ids = [aws_security_group.sg_db.id]
  publicly_accessible    = false
  multi_az               = false

  username             = var.catalog_db_username
  password             = random_password.catalog_password.result
  db_name              = var.catalog_db_name
  port                 = 3306
  parameter_group_name = aws_db_parameter_group.catalog_pg.name

  # Options démo
  auto_minor_version_upgrade = true
  backup_retention_period    = 1
  deletion_protection        = false
  skip_final_snapshot        = true

  tags = {
    Name        = "catalog-mysql"
    Project     = "the-store"
    Environment = var.environment
  }

  depends_on = [
    aws_internet_gateway.igw,
    aws_secretsmanager_secret_version.catalog_db_secret_v,
    aws_secretsmanager_secret_policy.catalog_allow_voclabs
  ]
}

###############################################
# 5️⃣ SEED automatique (exécuté APRÈS RDS UP) — via le BASTION
###############################################
# On pousse le fichier SQL sur le bastion puis on l'exécute depuis le bastion
# (le bastion est dans le VPC et atteint la RDS privée ; CloudShell ne le peut pas).
resource "null_resource" "seed_catalog" {
  triggers = {
    endpoint = aws_db_instance.catalog.address
    checksum = filesha256("${path.module}/catalog_seed.sql") # fichier à côté de ce .tf
  }

  # Connexion SSH au bastion
  connection {
    type        = "ssh"
    host        = aws_instance.bastion.public_ip
    user        = "ec2-user"
    private_key = file(var.ssh_private_key_path)  # ex: /home/cloudshell-user/.ssh/bastion.pem
  }

  # 1) Copier le SQL sur le bastion
  provisioner "file" {
    source      = "${path.module}/catalog_seed.sql"
    destination = "/home/ec2-user/catalog_seed.sql"
  }

  # 2) Exécuter le seed depuis le bastion vers la RDS privée
  provisioner "remote-exec" {
    inline = [
      # Installe le client MySQL si absent
      "sudo dnf -y install mysql || sudo yum -y install mysql || true",

      # Récupère le mot de passe depuis Secrets Manager (motive: pas de fuite de secret dans Terraform logs)
      "DB_PASSWORD=$(aws secretsmanager get-secret-value --region ${var.aws_region} --secret-id ${aws_secretsmanager_secret.catalog_db_secret.name} --query 'SecretString' --output text | python3 -c 'import sys,json;print(json.loads(sys.stdin.read())[\"password\"])')",

      # Exécute le seed
      "MYSQL_PWD=\"$DB_PASSWORD\" mysql -h ${aws_db_instance.catalog.address} -P 3306 -u ${var.catalog_db_username} ${var.catalog_db_name} < /home/ec2-user/catalog_seed.sql",

      # Vérification (log dans la sortie Terraform)
      "MYSQL_PWD=\"$DB_PASSWORD\" mysql -h ${aws_db_instance.catalog.address} -P 3306 -u ${var.catalog_db_username} -e 'SELECT COUNT(*) AS products FROM products;' ${var.catalog_db_name} || true"
    ]
  }

  depends_on = [aws_db_instance.catalog]
}


