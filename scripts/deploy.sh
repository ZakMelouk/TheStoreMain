#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Automated deployment of TheStore"

# --- Resolve paths relative to this script ---
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TF_DIR="${TF_DIR:-$REPO_ROOT/terraform}"

# --- Tool checks (before possible install of terraform) ---
command -v curl >/dev/null || { echo "❌ Missing curl"; exit 1; }
command -v unzip >/dev/null || { echo "❌ Missing unzip"; exit 1; }

# === 1️⃣ Install Terraform if not already present
if ! command -v terraform &> /dev/null; then
  echo "📦 Installing Terraform..."
  curl -fsSL -o "$SCRIPT_DIR/terraform.zip" https://releases.hashicorp.com/terraform/1.8.5/terraform_1.8.5_linux_amd64.zip
  unzip -q "$SCRIPT_DIR/terraform.zip" -d "$SCRIPT_DIR"
  mkdir -p "$HOME/bin"
  mv "$SCRIPT_DIR/terraform" "$HOME/bin/"
  export PATH="$HOME/bin:$PATH"
  rm "$SCRIPT_DIR/terraform.zip"
  echo "✅ Terraform successfully installed (PATH updated for this session)."
else
  echo "✅ Terraform already installed."
fi

# === 2️⃣ Generate local SSH key
SSH_DIR="$HOME/.ssh"
SSH_KEY="$SSH_DIR/the-store-key"
# save PEM at repo root for convenience
SSH_PEM="$REPO_ROOT/the-store-bastion-key.pem"

if [ ! -f "${SSH_KEY}" ]; then
  echo "🔑 Generating a new SSH key..."
  mkdir -p "$SSH_DIR"
  ssh-keygen -t rsa -b 4096 -f "${SSH_KEY}" -N "" -C "the-store"
  chmod 400 "${SSH_KEY}"
  echo "✅ SSH key generated: ${SSH_KEY}.pub"
else
  echo "✅ SSH key already exists: ${SSH_KEY}.pub"
fi

# === 3️⃣ Save private key as PEM (for the user)
if [ ! -f "${SSH_PEM}" ]; then
  cp "${SSH_KEY}" "${SSH_PEM}"
  chmod 400 "${SSH_PEM}"
  echo "💾 Local copy created: ${SSH_PEM}"
else
  echo "✅ PEM file already exists: ${SSH_PEM}"
fi

# === 5️⃣ Initialize and deploy Terraform (in ./terraform)
echo "⚙️ Initializing Terraform in: $TF_DIR"
terraform -chdir="$TF_DIR" init -no-color -upgrade

echo "🚀 Running Terraform deployment..."
terraform -chdir="$TF_DIR" apply -auto-approve -var "ssh_public_key=$(cat "${SSH_KEY}.pub")"

# === 6️⃣ Retrieve output information
echo ""
echo "📡 Retrieving deployment information..."
BASTION_IP="$(terraform -chdir="$TF_DIR" output -raw bastion_public_ip 2>/dev/null || echo "N/A")"

echo ""
echo "🎉 Deployment completed successfully!"
echo "--------------------------------------------"
echo "🔑 Private SSH key saved at: ${SSH_PEM}"
echo "🌐 Bastion public IP: ${BASTION_IP}"
echo "--------------------------------------------"
echo ""
echo "💡 To connect:"
echo "ssh -i \"${SSH_PEM}\" ec2-user@\"${BASTION_IP}\""
