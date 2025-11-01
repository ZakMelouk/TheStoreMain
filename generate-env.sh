#!/usr/bin/env bash
set -euo pipefail

# --- CONFIG ---
AWS_REGION="eu-west-3"
SECRET_NAME="catalog-db-credentials"
TF_DIR="."         # dossier contenant ton code Terraform
OUTPUT_FILE=".env"

# --- Vérifications ---
command -v aws >/dev/null || { echo "❌ AWS CLI manquant"; exit 1; }
command -v terraform >/dev/null || { echo "❌ Terraform manquant"; exit 1; }

echo "==> Lecture des outputs Terraform..."
RDS_ENDPOINT=$(cd "$TF_DIR" && terraform output -raw catalog_rds_endpoint)
DB_NAME=$(cd "$TF_DIR" && terraform output -raw catalog_db_name)
DB_USER=$(cd "$TF_DIR" && terraform output -raw catalog_db_username)

echo "==> Récupération du mot de passe dans Secrets Manager..."
RAW_SECRET=$(aws secretsmanager get-secret-value \
  --region "$AWS_REGION" \
  --secret-id "$SECRET_NAME" \
  --query 'SecretString' --output text)

DB_PASSWORD=$(python3 - <<'PY'
import json, os
print(json.loads(os.environ["RAW_SECRET"])["password"])
PY
)

echo "==> Génération du fichier .env..."
cat > "$OUTPUT_FILE" <<EOF
# === AUTO-GENERATED .ENV ===
AWS_REGION=$AWS_REGION
CATALOG_DB_ENDPOINT=${RDS_ENDPOINT}:3306
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
EOF

echo ""
echo "✅ Fichier .env créé avec succès :"
cat "$OUTPUT_FILE" | sed 's/DB_PASSWORD=.*/DB_PASSWORD=****/'
echo ""
echo "➡️ Copie ce fichier .env dans VS Code (à la racine du projet)"
echo "➡️ Puis exécute : docker compose up -d --build"
