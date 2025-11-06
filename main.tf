# 1️⃣ Create the main VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"      # Network address range
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "the-store-vpc"
  }
}

# 2️⃣ Create the Internet Gateway for the VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id  # Attach the gateway to the VPC

  tags = {
    Name = "the-store-igw"
  }
}

# 3️⃣ Create two public subnets (in 2 availability zones)
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true  # Assign a public IP to instances

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

# 4️⃣ Create the public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"           # Route all traffic
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# 5️⃣ Associate the route table with the public subnets
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}
