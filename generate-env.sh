#!/usr/bin/env bash
set -euo pipefail

# --- Config overridable via variables d'env (sinon valeurs par défaut) ---
AWS_REGION="${AWS_REGION:-us-east-1}"
TF_DIR="${TF_DIR:-.}"
OUTPUT_FILE="${OUTPUT_FILE:-.env}"

# TUNNEL local (Option A) : host/port visibles depuis tes conteneurs
MYSQL_HOST="${MYSQL_HOST:-host.docker.internal}"
MYSQL_PORT="${MYSQL_PORT:-3307}"

# --- Vérifications outils ---
command -v aws >/dev/null || { echo "❌ AWS CLI manquant"; exit 1; }
command -v terraform >/dev/null || { echo "❌ Terraform manquant"; exit 1; }
command -v python3 >/dev/null || { echo "❌ python3 manquant"; exit 1; }

echo "==> Lecture des outputs Terraform..."
RDS_ENDPOINT=$(cd "$TF_DIR" && terraform output -raw catalog_rds_endpoint)   # ex: catalog-mysql.xxx.rds.amazonaws.com
DB_NAME=$(cd "$TF_DIR" && terraform output -raw catalog_db_name)
DB_USER=$(cd "$TF_DIR" && terraform output -raw catalog_db_username)
SECRET_ARN=$(cd "$TF_DIR" && terraform output -raw catalog_secret_arn)

echo "==> Récupération du mot de passe dans Secrets Manager..."
RAW_SECRET=$(aws secretsmanager get-secret-value \
  --region "$AWS_REGION" \
  --secret-id "$SECRET_ARN" \
  --query 'SecretString' --output text)

export RAW_SECRET
DB_PASSWORD=$(python3 - <<'PY'
import json, os
print(json.loads(os.environ["RAW_SECRET"])["password"])
PY
)

echo "==> Génération du fichier .env..."
cat > "$OUTPUT_FILE" <<EOF
# === AUTO-GENERATED .ENV ===
AWS_REGION=$AWS_REGION

# Endpoint RDS (info)
CATALOG_DB_ENDPOINT=${RDS_ENDPOINT}:3306

# Endpoint utilisé par l'app via le TUNNEL SSH local
MYSQL_HOST=${MYSQL_HOST}
MYSQL_PORT=${MYSQL_PORT}

# Identifiants DB
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}

# Si ton app préfère un DSN unique, dé-commente et adapte :
# RETAIL_CATALOG_PERSISTENCE_URL=mysql://${DB_USER}:${DB_PASSWORD}@tcp(${MYSQL_HOST}:${MYSQL_PORT})/${DB_NAME}?parseTime=true
EOF

echo "✅ .env créé :"
sed 's/DB_PASSWORD=.*/DB_PASSWORD=****/' "$OUTPUT_FILE"
