# =============================
# Bastion Host EC2 Instance
# =============================

# 1️⃣ SSH Key pair (already generated locally)
resource "aws_key_pair" "bastion_key" {
  key_name   = "the-store-bastion-key"
  public_key = var.ssh_public_key
}

# 2️⃣ EC2 Bastion Instance
resource "aws_instance" "bastion" {
  ami                    = "ami-0c94855ba95c71c99"  # Amazon Linux 2 (us-east-1)
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_a.id
  key_name               = aws_key_pair.bastion_key.key_name
  vpc_security_group_ids = [aws_security_group.sg_bastion.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y postgresql mysql redis awscli telnet net-tools git

              # Welcome message
              echo "==========================================" >> /etc/motd
              echo " Welcome to The Store Bastion Host " >> /etc/motd
              echo " Connected via SSH - Admin access only " >> /etc/motd
              echo "==========================================" >> /etc/motd

              # Make motd visible at each login
              chmod 644 /etc/motd
              EOF

  tags = {
    Name = "bastion-host"
  }

  depends_on = [aws_internet_gateway.igw]
}

# 3️⃣ Elastic IP for fixed public IP
resource "aws_eip" "bastion_eip" {
  domain = "vpc"

  tags = {
    Name = "the-store-bastion-eip"
  }
}

# 4️⃣ EIP ↔ Bastion Association
resource "aws_eip_association" "bastion_assoc" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion_eip.id
}

# =============================
# Bastion Host - AZ b (secondary)
# =============================

resource "aws_instance" "bastion_b" {
  ami                    = "ami-0c94855ba95c71c99"  # Amazon Linux 2 us-east-1
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_b.id
  key_name               = aws_key_pair.bastion_key.key_name
  vpc_security_group_ids = [aws_security_group.sg_bastion.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y postgresql mysql redis awscli telnet net-tools git
              echo "==========================================" >> /etc/motd
              echo " Secondary Bastion Host (AZ-b)" >> /etc/motd
              echo "==========================================" >> /etc/motd
              chmod 644 /etc/motd
              EOF

  tags = {
    Name = "bastion-host-b"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_eip" "bastion_eip_b" {
  domain = "vpc"
  tags = { Name = "the-store-bastion-eip-b" }
}

resource "aws_eip_association" "bastion_assoc_b" {
  instance_id   = aws_instance.bastion_b.id
  allocation_id = aws_eip.bastion_eip_b.id
}
