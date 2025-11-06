# Dynamic Amazon Linux 2 AMI
data "aws_ami" "al2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

variable "k8s_instance_type" {
  description = "EC2 instance type for K8S nodes"
  default     = "t3.micro"
}

# 1) Master in private subnet (AZ a) -> subnet private_c
resource "aws_instance" "k8s_master" {
  ami                    = data.aws_ami.al2.id
  instance_type          = var.k8s_instance_type
  subnet_id              = aws_subnet.private_c.id
  key_name               = aws_key_pair.bastion_key.key_name
  vpc_security_group_ids = [aws_security_group.sg_k8s_nodes.id]

  # No public IP in private subnet -> leave empty

  root_block_device {
    volume_size = 16
    volume_type = "gp3"
  }

  tags = {
    Name    = "k8s-master"
    Role    = "master"
    Project = "the-store"
  }

  # Private nodes need NAT to access the internet
  depends_on = [aws_nat_gateway.nat]
}

# 2) Workers in private subnets (spread across AZ a/b) -> subnets private_c / private_d
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
