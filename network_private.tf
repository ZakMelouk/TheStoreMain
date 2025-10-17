# =============================
# Sous-réseaux privés
# =============================
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-b"
  }
}

# =============================
# Elastic IP (pour la NAT Gateway)
# =============================
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "the-store-nat-eip"
  }
}

# =============================
# NAT Gateway (sortie Internet pour les subnets privés)
# =============================
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_a.id
  tags = {
    Name = "the-store-nat"
  }

  depends_on = [aws_internet_gateway.igw]
}

# =============================
# Table de routage privée
# =============================
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private-rt"
  }
}

# =============================
# Associations entre subnets privés et table privée
# =============================
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}
