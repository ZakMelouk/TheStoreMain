#!/usr/bin/env bash
set -euo pipefail

# --- CONFIG ---
AWS_REGION="eu-west-3"
TF_DIR="./terraform"         # dossier contenant ton code Terraform
OUTPUT_FILE=".env"

# --- Vérifications ---
command -v aws >/dev/null || { echo "❌ AWS CLI manquant"; exit 1; }
command -v terraform >/dev/null || { echo "❌ Terraform manquant"; exit 1; }

echo "==> Lecture des outputs Terraform..."
RDS_ENDPOINT=$(cd "$TF_DIR" && terraform output -raw catalog_rds_endpoint)
DB_NAME=$(cd "$TF_DIR" && terraform output -raw catalog_db_name)
DB_USER=$(cd "$TF_DIR" && terraform output -raw catalog_db_username)
SECRET_ARN=$(cd "$TF_DIR" && terraform output -raw catalog_secret_arn)  # ✅ nouvel output

echo "==> Récupération du mot de passe dans Secrets Manager..."
RAW_SECRET=$(aws secretsmanager get-secret-value \
  --region "$AWS_REGION" \
  --secret-id "$SECRET_ARN" \
  --query 'SecretString' --output text)  # ✅ on utilise l’ARN, pas le nom

export RAW_SECRET   # ✅ rendre dispo pour le process Python ci-dessous
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
sed 's/DB_PASSWORD=.*/DB_PASSWORD=****/' "$OUTPUT_FILE"
echo ""
echo "➡️ Copie ce fichier .env dans VS Code (à la racine du projet)"
echo "➡️ Puis exécute : docker compose up -d --build"
