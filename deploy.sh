#!/bin/bash
set -e

echo "🚀 Déploiement TheStore simplifié"

# === 1️⃣ Installer Terraform localement si absent
if ! command -v terraform &> /dev/null
then
  echo "📦 Téléchargement de Terraform..."
  curl -fsSL -o terraform.zip https://releases.hashicorp.com/terraform/1.8.5/terraform_1.8.5_linux_amd64.zip
  unzip -q terraform.zip
  mv terraform ~/bin/ 2>/dev/null || mkdir -p ~/bin && mv terraform ~/bin/
  export PATH="$HOME/bin:$PATH"
  rm terraform.zip
  echo "✅ Terraform installé localement !"
else
  echo "✅ Terraform déjà présent"
fi

# === 2️⃣ Génération de la clé SSH
SSH_KEY="$HOME/.ssh/the-store-key"
if [ ! -f "${SSH_KEY}" ]; then
  echo "🔑 Génération d'une clé SSH..."
  mkdir -p ~/.ssh
  ssh-keygen -t rsa -b 4096 -f "${SSH_KEY}" -N "" -C "the-store"
  echo "✅ Clé SSH générée : ${SSH_KEY}.pub"
else
  echo "✅ Clé SSH déjà existante"
fi

# === 3️⃣ Clonage du repo
if [ ! -d "TheStoreMain" ]; then
  echo "📥 Clonage du dépôt GitHub public..."
  git clone https://github.com/ZakMelouk/TheStoreMain.git
else
  echo "✅ Dépôt déjà présent"
fi

cd TheStoreMain

# === 4️⃣ Initialisation et apply Terraform
echo "⚙️ Initialisation Terraform..."
terraform init -no-color -upgrade

echo "🚀 Application Terraform..."
terraform apply -auto-approve -var "ssh_public_key=$(cat ~/.ssh/the-store-key.pub)"

echo "🎉 Déploiement terminé !"
