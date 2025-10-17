# =============================
# Bastion Host EC2 Instance
# =============================

# 1️⃣ SSH Key pair (déjà générée en local)
resource "aws_key_pair" "bastion_key" {
  key_name   = "the-store-bastion-key"
  public_key = var.ssh_public_key
}

# 2️⃣ Instance EC2 Bastion
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

              # Petit message de bienvenue
              echo "==========================================" >> /etc/motd
              echo " Welcome to The Store Bastion Host " >> /etc/motd
              echo " Connected via SSH - Admin access only " >> /etc/motd
              echo "==========================================" >> /etc/motd

              # Rendre le motd visible à chaque login
              chmod 644 /etc/motd
              EOF

  tags = {
    Name = "bastion-host"
  }

  depends_on = [aws_internet_gateway.igw]
}

# 3️⃣ Elastic IP pour IP publique fixe
resource "aws_eip" "bastion_eip" {
  domain = "vpc"

  tags = {
    Name = "the-store-bastion-eip"
  }
}

# 4️⃣ Association EIP ↔ Bastion
resource "aws_eip_association" "bastion_assoc" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion_eip.id
}
