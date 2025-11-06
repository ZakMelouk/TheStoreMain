
🧩 The Store — Run the Catalog Service Locally (Connected to AWS RDS)
This guide explains how to run the Catalog microservice locally while securely connecting to the private RDS MySQL database through the AWS Bastion Host.

1️⃣ Clone the Repository
``` git clone https://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@github.com/ZakMelouk/TheStoreMain.git    ```
cd TheStoreMain

💡 If the repository is private, use a GitHub Personal Access Token in the URL.

2️⃣ Prepare and Execute Deployment Scripts
Make the setup scripts executable and run them:
``chmod +x scripts/deploy.sh
./scripts/deploy.sh``

``chmod +x scripts/generate-env.sh
./scripts/generate-env.sh``

These scripts initialize the project environment and generate the required configuration files.

3️⃣ Download and Place the Required Files
Obtain the following files from your shared resources (e.g., internal drive, Google Drive, or AWS S3):

the-store-bastion-key.pem
SSH key for the Bastion Host
Any accessible local directory (e.g. ~/keys/ or C:\keys\)

.env
Environment variables for the Catalog service
the-store-main/src/catalog/.env
docker-compose.yml
Updated Docker Compose for the Catalog service
Replace the one in the-store-main/src/catalog/

Example structure:
TheStoreMain/
└── src/
    └── catalog/
        ├── .env
        └── docker-compose.yml


4️⃣ Configure the Bastion Key Permissions
🪟 On Windows (PowerShell)
``icacls "C:\yourpath\the-store-bastion-key.pem" /inheritance:r /grant:r "$($env:USERNAME):R"``

🐧 On Linux / macOS
``chmod 400 ~/keys/the-store-bastion-key.pem``

⚠️ These commands restrict access to your SSH key, which is required for secure SSH connections.

5️⃣ Establish an SSH Tunnel to the Private Database
Run this command from the same directory where your .pem file is located:
``ssh -i ./the-store-bastion-key.pem -N -L 3307:<RDS_ENDPOINT>:3306 ec2-user@<BASTION_EIP>``

🔍 What This Does
Opens a secure SSH tunnel between your local machine and the AWS Bastion Host.


Forwards all traffic from localhost:3307 → the private RDS MySQL instance (port 3306).


After this, you can access the remote database as if it were local.


➡️ Keep this terminal open while running the Catalog service.

6️⃣ Launch the Catalog Service Locally
In a new terminal, navigate to the Catalog directory and start the service:
``cd the-store-main/src/catalog
docker compose up -d --build catalog
``
✅ This:
Builds and starts the Catalog container


Connects automatically to the RDS MySQL database through the SSH tunnel


To confirm it’s running:
docker ps


7️⃣ SSH Access — Bastion ➜ Master and Worker Nodes
Retrieve Terraform Outputs

bastion_public_ip
Bastion Host public IP

k8s_master_private_ip
Kubernetes Master Node private IP

k8s_worker_private_ips
Kubernetes Worker Nodes private IPs


Step-by-Step SSH Access
1️⃣ Open a terminal in the same directory as your .pem file.
If you haven’t yet set permissions:
``icacls "C:\yourpath\the-store-bastion-key.pem" /inheritance:r /grant:r "$($env:USERNAME):R"``

2️⃣ Copy the key to the Bastion Host:
``scp -i ./the-store-bastion-key.pem ./the-store-bastion-key.pem ec2-user@<BASTION_EIP>:~``

3️⃣ SSH into the Bastion Host:
``ssh -i ./the-store-bastion-key.pem ec2-user@<BASTION_EIP>``
Protect the key:

``chmod 400 ~/the-store-bastion-key.pem
``

4️⃣ From the Bastion, SSH into your Master Node:
``ssh -i ~/the-store-bastion-key.pem ec2-user@<MASTER_PRIVATE_IP>``

5️⃣ (Optional) Connect to Worker Nodes:
``ssh -i ~/the-store-bastion-key.pem ec2-user@<WORKER1_PRIVATE_IP>
ssh -i ~/the-store-bastion-key.pem ec2-user@<WORKER2_PRIVATE_IP>``
