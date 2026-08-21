# Definisemo aws_ami image da bi dobili pravu ami verziju za region
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# 1. Kreiranje VPC-a
resource "aws_vpc" "devops_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "devops-project-vpc"
  }
}

# 2. Kreiranje Pubilc Subnet-a
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.devops_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
}

# 3. Internete Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.devops_vpc.id

  tags = {
    Name = "devops_igw"
  }
}

# 4. Route Tabel
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.devops_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "devops-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 5. Security Groupe
resource "aws_security_group" "devops_sg" {
  name        = "devops-project-sg"
  description = "Dozvoli SSH, HTTP i App portove"
  vpc_id      = aws_vpc.devops_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 32762
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-sg"
  }
}

resource "aws_key_pair" "devops_key" {
  key_name   = "devops_key"
  public_key = file("~/.ssh/devops-key.pub")
}

# 6. EC2 instanca
resource "aws_instance" "devops-server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.devops_sg.id]
  key_name               = aws_key_pair.devops_key.key_name

  user_data = <<-EOF
               #!/bin/bash
               sudo apt-get update -y
               sudo apt-get install -y docker.io
               sudo systemctl start docker
               sudo systemctl enable docker
               sudo usermod -aG docker ubuntu

               curl -sfL https://get.k3s.io | sh -

               mkdir -p /home/ubuntu/.kube
               cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
               chown -R ubuntu:ubuntu /home/ubuntu/.kube
               chmod 644 /etc/rancher/k3s/k3s.yaml

               until /usr/local/bin/kubectl get nodes | grep -q "Ready"; do
                sleep 5
               done

               /usr/local/bin/kubectl create namespace argocd
               /usr/local/bin/kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

               /usr/local/bin/kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort", "ports": [{"port": 80, "targetPort": 8080, "nodePort": 30080}]}}'
               EOF

  # 1. Update paketa i instalacija docker-a
  # 2. Instalacija k3s-a
  # 3. Podesavanje dozvola za kubectl za ubuntu korisnika
  # 4. instalacija ArgoCD-a
  # 5. izlaganje ArgoCD-a na NodePort 30080

  tags = {
    Name = "devops-k8s-node"
  }
}