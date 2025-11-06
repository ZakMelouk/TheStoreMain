# ==============================================================
# SECURITY GROUPS CONFIGURATION - The Store (Simplified for POC)
# ==============================================================
# Context:
# - Microservices run locally (Kubernetes cluster)
# - AWS hosts only databases, cache, and storage
# - A Bastion Host provides secure administrative access
# ==============================================================


# ==============================================================
# 1️⃣ Bastion Host Security Group (for admin SSH access)
# --------------------------------------------------------------
# Allows SSH only from your local IP.
# Used by admins to connect to private AWS resources (RDS, Redis, etc.).
# ==============================================================
resource "aws_security_group" "sg_bastion" {
  name        = "bastion-sg"
  description = "SSH access for Bastion Host (admin access only)"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH access from admin workstation"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}



# ==============================================================
# 2️⃣ Public Security Group (for Internet access)
# --------------------------------------------------------------
# Used for instances that require Internet access (e.g. Bastion Host).
# Allows HTTP/HTTPS outbound and optionally inbound (if needed).
# ==============================================================
resource "aws_security_group" "sg_public" {
  name        = "public-sg"
  description = "Allow public web traffic for Bastion or updates"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Optional HTTPS access (if Bastion has a web interface)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic (software updates, API calls)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "public-sg"
  }
}



# ==============================================================
# 3️⃣ Database Security Group (PostgreSQL / MySQL)
# --------------------------------------------------------------
# Used for RDS instances (Orders, Catalog microservices).
# Access allowed from the Bastion Host AND optionally your local IP
# (for direct testing without VPN or SSH tunnel).
# ==============================================================
resource "aws_security_group" "sg_db" {
  name        = "database-sg"
  description = "Database access (PostgreSQL & MySQL)"
  vpc_id      = aws_vpc.main.id

  # Access from Bastion Host
  ingress {
    description = "Database access from Bastion Host"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.sg_bastion.id]
  }

  ingress {
    description = "MySQL access from Bastion Host"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.sg_bastion.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "database-sg"
  }
}

# 3️⃣ Security Group (allow only Bastion)
resource "aws_security_group" "sg_redis" {
  name        = "redis-sg"
  description = "Allow Bastion access to Redis"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow Redis access from Bastion"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    security_groups = [aws_security_group.sg_bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "redis-sg"
  }
}

resource "aws_security_group" "sg_k8s_nodes" {
  name   = "k8s-nodes-sg"
  vpc_id = aws_vpc.main.id

  # SSH from bastion only
  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_bastion.id]
  }

  # Intra-cluster (simple and effective)
  ingress {
    description = "All within k8s nodes"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Internet egress (via NAT)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "sg-k8s-nodes" }
}
