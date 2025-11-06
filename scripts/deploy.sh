#!/bin/bash
set -e

echo "🚀 Automated deployment of TheStore"

# === 1️⃣ Install Terraform if not already present
if ! command -v terraform &> /dev/null
then
  echo "📦 Installing Terraform..."
  curl -fsSL -o terraform.zip https://releases.hashicorp.com/terraform/1.8.5/terraform_1.8.5_linux_amd64.zip
  unzip -q terraform.zip
  mkdir -p ~/bin
  mv terraform ~/bin/
  export PATH="$HOME/bin:$PATH"
  rm terraform.zip
  echo "✅ Terraform successfully installed."
else
  echo "✅ Terraform already installed."
fi

# === 2️⃣ Generate local SSH key
SSH_DIR="$HOME/.ssh"
SSH_KEY="$SSH_DIR/the-store-key"
SSH_PEM="./the-store-bastion-key.pem"

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

# === 5️⃣ Initialize and deploy Terraform
echo "⚙️ Initializing Terraform..."
terraform init -no-color -upgrade

echo "🚀 Running Terraform deployment..."
terraform apply -auto-approve -var "ssh_public_key=$(cat ~/.ssh/the-store-key.pub)"

# === 6️⃣ Retrieve output information
echo ""
echo "📡 Retrieving deployment information..."
BASTION_IP=$(terraform output -raw bastion_public_ip 2>/dev/null || echo "N/A")

echo ""
echo "🎉 Deployment completed successfully!"
echo "--------------------------------------------"
echo "🔑 Private SSH key saved at: ${SSH_PEM}"
echo "🌐 Bastion public IP: ${BASTION_IP}"
echo "--------------------------------------------"
echo ""
echo "💡 To connect:"
echo "ssh -i ${SSH_PEM} ec2-user@${BASTION_IP}"
