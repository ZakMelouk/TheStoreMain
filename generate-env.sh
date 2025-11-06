#!/usr/bin/env bash
set -euo pipefail

# --- Config overridable via environment variables (otherwise default values) ---
AWS_REGION="${AWS_REGION:-us-east-1}"
TF_DIR="${TF_DIR:-.}"
OUTPUT_FILE="${OUTPUT_FILE:-.env}"

# Local TUNNEL (Option A): host/port visible from your containers
MYSQL_HOST="${MYSQL_HOST:-host.docker.internal}"
MYSQL_PORT="${MYSQL_PORT:-3307}"

# --- Tool checks ---
command -v aws >/dev/null || { echo "❌ Missing AWS CLI"; exit 1; }
command -v terraform >/dev/null || { echo "❌ Missing Terraform"; exit 1; }
command -v python3 >/dev/null || { echo "❌ Missing python3"; exit 1; }

echo "==> Reading Terraform outputs..."
RDS_ENDPOINT=$(cd "$TF_DIR" && terraform output -raw catalog_rds_endpoint)   # e.g. catalog-mysql.xxx.rds.amazonaws.com
DB_NAME=$(cd "$TF_DIR" && terraform output -raw catalog_db_name)
DB_USER=$(cd "$TF_DIR" && terraform output -raw catalog_db_username)
SECRET_ARN=$(cd "$TF_DIR" && terraform output -raw catalog_secret_arn)

echo "==> Retrieving password from Secrets Manager..."
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

echo "==> Generating .env file..."
cat > "$OUTPUT_FILE" <<EOF
# === AUTO-GENERATED .ENV ===
AWS_REGION=$AWS_REGION

# RDS Endpoint (info)
CATALOG_DB_ENDPOINT=${RDS_ENDPOINT}:3306

# Endpoint used by the app via the local SSH TUNNEL
MYSQL_HOST=${MYSQL_HOST}
MYSQL_PORT=${MYSQL_PORT}

# DB credentials
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}

# If your app prefers a single DSN, uncomment and adjust:
# RETAIL_CATALOG_PERSISTENCE_URL=mysql://${DB_USER}:${DB_PASSWORD}@tcp(${MYSQL_HOST}:${MYSQL_PORT})/${DB_NAME}?parseTime=true
EOF

echo "✅ .env created:"
sed 's/DB_PASSWORD=.*/DB_PASSWORD=****/' "$OUTPUT_FILE"
