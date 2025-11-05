# AMI Amazon Linux 2 dynamique
data "aws_ami" "al2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

variable "k8s_instance_type" {
  description = "Type d'instance EC2 pour les nœuds K8S"
  default     = "t3.micro"
}

# 1) Master en privé (AZ a) -> subnet private_c
resource "aws_instance" "k8s_master" {
  ami                    = data.aws_ami.al2.id
  instance_type          = var.k8s_instance_type
  subnet_id              = aws_subnet.private_c.id
  key_name               = aws_key_pair.bastion_key.key_name
  vpc_security_group_ids = [aws_security_group.sg_k8s_nodes.id]

  # PAS d'IP publique en privé -> ne rien mettre

  root_block_device {
    volume_size = 16
    volume_type = "gp3"
  }

  tags = {
    Name    = "k8s-master"
    Role    = "master"
    Project = "the-store"
  }

  # Les nœuds privés ont besoin de la NAT pour sortir
  depends_on = [aws_nat_gateway.nat]
}

# 2) Workers en privé (répartis AZ a/b) -> subnets private_c / private_d
resource "aws_instance" "k8s_worker" {
  count                  = 2
  ami                    = data.aws_ami.al2.id
  instance_type          = var.k8s_instance_type
  subnet_id              = count.index == 0 ? aws_subnet.private_c.id : aws_subnet.private_d.id
  key_name               = aws_key_pair.bastion_key.key_name
  vpc_security_group_ids = [aws_security_group.sg_k8s_nodes.id]

  root_block_device {
    volume_size = 16
    volume_type = "gp3"
  }

  tags = {
    Name    = "k8s-worker-${count.index + 1}"
    Role    = "worker"
    Project = "the-store"
  }

  depends_on = [aws_nat_gateway.nat]
}


