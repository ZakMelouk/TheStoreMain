#!/bin/bash
set -e

echo "🚀 Déploiement automatisé de TheStore"

# === 1️⃣ Installation de Terraform si absent
if ! command -v terraform &> /dev/null
then
  echo "📦 Installation de Terraform..."
  curl -fsSL -o terraform.zip https://releases.hashicorp.com/terraform/1.8.5/terraform_1.8.5_linux_amd64.zip
  unzip -q terraform.zip
  mkdir -p ~/bin
  mv terraform ~/bin/
  export PATH="$HOME/bin:$PATH"
  rm terraform.zip
  echo "✅ Terraform installé avec succès."
else
  echo "✅ Terraform déjà présent."
fi

# === 2️⃣ Génération de la clé SSH locale
SSH_DIR="$HOME/.ssh"
SSH_KEY="$SSH_DIR/the-store-key"
SSH_PEM="./the-store-bastion-key.pem"

if [ ! -f "${SSH_KEY}" ]; then
  echo "🔑 Génération d'une nouvelle clé SSH..."
  mkdir -p "$SSH_DIR"
  ssh-keygen -t rsa -b 4096 -f "${SSH_KEY}" -N "" -C "the-store"
  chmod 400 "${SSH_KEY}"
  echo "✅ Clé SSH générée : ${SSH_KEY}.pub"
else
  echo "✅ Clé SSH déjà existante : ${SSH_KEY}.pub"
fi

# === 3️⃣ Sauvegarde de la clé privée sous forme PEM (pour l’utilisateur)
if [ ! -f "${SSH_PEM}" ]; then
  cp "${SSH_KEY}" "${SSH_PEM}"
  chmod 400 "${SSH_PEM}"
  echo "💾 Copie locale créée : ${SSH_PEM}"
else
  echo "✅ Fichier PEM déjà présent : ${SSH_PEM}"
fi

# === 4️⃣ Clonage du dépôt GitHub
if [ ! -d "TheStoreMain" ]; then
  echo "📥 Clonage du dépôt GitHub public..."
  git clone https://github.com/ZakMelouk/TheStoreMain.git
else
  echo "✅ Dépôt GitHub déjà présent."
fi

cd TheStoreMain

# === 5️⃣ Initialisation et déploiement Terraform
echo "⚙️ Initialisation de Terraform..."
terraform init -no-color -upgrade

echo "🚀 Lancement du déploiement Terraform..."
terraform apply -auto-approve -var "ssh_public_key=$(cat ~/.ssh/the-store-key.pub)"

# === 6️⃣ Récupération des infos de sortie
echo ""
echo "📡 Récupération des informations de déploiement..."
BASTION_IP=$(terraform output -raw bastion_public_ip 2>/dev/null || echo "N/A")

echo ""
echo "🎉 Déploiement terminé avec succès !"
echo "--------------------------------------------"
echo "🔑 Clé SSH privée sauvegardée : ${SSH_PEM}"
echo "🌐 IP publique du Bastion : ${BASTION_IP}"
echo "--------------------------------------------"
echo ""
echo "💡 Pour te connecter :"
echo "ssh -i ${SSH_PEM} ec2-user@${BASTION_IP}"
