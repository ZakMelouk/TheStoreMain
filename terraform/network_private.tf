# =============================
# Private subnets
# =============================
resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-b"
  }
}

resource "aws_subnet" "private_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.5.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-c"
  }
}

resource "aws_subnet" "private_d" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.6.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet-d"
  }
}

# =============================
# Elastic IP (for the NAT Gateway)
# =============================
resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = {
    Name = "the-store-nat-eip"
  }
}

# Elastic IP for the 2nd NAT Gateway (AZ b)
resource "aws_eip" "nat_eip_b" {
  domain = "vpc"
  tags = {
    Name = "the-store-nat-eip-b"
  }
}

# =============================
# NAT Gateway (Internet access for private subnets)
# =============================
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_a.id
  tags = {
    Name = "the-store-nat"
  }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_eip_b.id
  subnet_id     = aws_subnet.public_b.id
  tags = {
    Name = "the-store-nat-b"
  }
  depends_on = [aws_internet_gateway.igw]
}

# =============================
# Private route tables
# =============================
# Existing private table (AZ a) -> NAT A
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

# New private table (AZ b) -> NAT B  <-- MINIMAL ADDITION
resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_b.id
  }

  tags = {
    Name = "private-rt-b"
  }
}

# Private DB table (no Internet access)
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "rt-private-db" }
}

# =============================
# Associations between private subnets and private route tables
# =============================
# DB (isolated)
resource "aws_route_table_association" "db_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_db.id
}

resource "aws_route_table_association" "db_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_db.id
}

# Apps (K8s)
resource "aws_route_table_association" "app_c" {
  subnet_id      = aws_subnet.private_c.id
  route_table_id = aws_route_table.private.id
}

# Associate AZ b to private table b (-> NAT B)  <-- MINIMAL CHANGE
resource "aws_route_table_association" "app_d" {
  subnet_id      = aws_subnet.private_d.id
  route_table_id = aws_route_table.private_b.id
}

# =============================
# VPC Gateway Endpoint for DynamoDB
# =============================
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private_db.id
  ]

  tags = {
    Name = "the-store-dynamodb-endpoint"
  }
}

