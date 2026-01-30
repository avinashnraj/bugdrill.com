# Terraform configuration for K3s on AWS EC2
# Deploys a single t4g.micro instance (ARM-based, cheapest option)
# Free tier eligible for 12 months

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "bugdrill"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "my_ip" {
  description = "Your IP address for SSH access (CIDR notation)"
  type        = string
  # Set this to your IP: "203.0.113.0/32"
}

# Data source for latest Ubuntu ARM64 AMI
data "aws_ami" "ubuntu_arm64" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# VPC and Networking
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "${var.project_name}-vpc"
    Project = var.project_name
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project_name}-igw"
    Project = var.project_name
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-public-subnet"
    Project = var.project_name
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "${var.project_name}-public-rt"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "k3s" {
  name        = "${var.project_name}-k3s-sg"
  description = "Security group for K3s cluster"
  vpc_id      = aws_vpc.main.id

  # SSH access (restricted to your IP)
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # API Server (for kubectl access from your machine)
  ingress {
    description = "K3s API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # Outbound traffic
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-k3s-sg"
    Project = var.project_name
  }
}

# SSH Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-deployer"
  public_key = file(var.ssh_public_key_path)

  tags = {
    Name    = "${var.project_name}-deployer-key"
    Project = var.project_name
  }
}

# EBS Volume for PostgreSQL data persistence
resource "aws_ebs_volume" "postgres_data" {
  availability_zone = "${var.aws_region}a"
  size              = 20 # GB (Free tier: 30GB)
  type              = "gp3"
  encrypted         = true

  tags = {
    Name    = "${var.project_name}-postgres-data"
    Project = var.project_name
  }
}

# EC2 Instance
resource "aws_instance" "k3s" {
  ami           = data.aws_ami.ubuntu_arm64.id
  instance_type = "t4g.micro" # 2 vCPU, 1GB RAM, ARM-based, free tier eligible
  
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.k3s.id]
  key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true

  # Root volume
  root_block_device {
    volume_size           = 20 # GB
    volume_type           = "gp3"
    delete_on_termination = false
    encrypted             = true
  }

  user_data = templatefile("${path.module}/user-data.sh", {
    project_name = var.project_name
  })

  tags = {
    Name    = "${var.project_name}-k3s"
    Project = var.project_name
    Type    = "k3s-server"
  }

  lifecycle {
    ignore_changes = [user_data]
  }
}

# Attach EBS volume for PostgreSQL
resource "aws_volume_attachment" "postgres_data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.postgres_data.id
  instance_id = aws_instance.k3s.id
}

# Elastic IP (optional, recommended for stable endpoint)
resource "aws_eip" "k3s" {
  domain   = "vpc"
  instance = aws_instance.k3s.id

  tags = {
    Name    = "${var.project_name}-eip"
    Project = var.project_name
  }
}

# Outputs
output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.k3s.id
}

output "public_ip" {
  description = "Public IP address (Elastic IP)"
  value       = aws_eip.k3s.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh ubuntu@${aws_eip.k3s.public_ip}"
}

output "kubeconfig_command" {
  description = "Command to get kubeconfig"
  value       = "ssh ubuntu@${aws_eip.k3s.public_ip} 'sudo cat /etc/rancher/k3s/k3s.yaml' | sed 's/127.0.0.1/${aws_eip.k3s.public_ip}/g' > ~/.kube/bugdrill-config"
}
