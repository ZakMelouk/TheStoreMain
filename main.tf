# 1️⃣ Crée la VPC principale
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"      # Plage d’adresses du réseau
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "the-store-vpc"
  }
}

# 2️⃣ Crée la passerelle Internet pour la VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id  # Associe la gateway à la VPC

  tags = {
    Name = "the-store-igw"
  }
}

# 3️⃣ Crée deux sous-réseaux publics (dans 2 zones dispo)
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true  # Donne une IP publique aux instances

  tags = {
    Name = "public-subnet-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-b"
  }
}

# 4️⃣ Crée la table de routage publique
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"           # Route tout le trafic
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# 5️⃣ Associe la route aux subnets publics
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}
