# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group for Ansible Control Node
resource "aws_security_group" "control_node" {
  name        = "${var.project_name}-control-node-sg"
  description = "Security group for Ansible control node"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Change this to your IP for security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-control-node-sg"
  }
}

# Security Group for Linux Hosts
resource "aws_security_group" "linux_hosts" {
  name        = "${var.project_name}-linux-hosts-sg"
  description = "Security group for Linux managed hosts"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.control_node.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Change this to your IP for security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-linux-hosts-sg"
  }
}

# Security Group for Windows Hosts
resource "aws_security_group" "windows_hosts" {
  name        = "${var.project_name}-windows-hosts-sg"
  description = "Security group for Windows managed hosts"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5985
    to_port         = 5986
    protocol        = "tcp"
    security_groups = [aws_security_group.control_node.id]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Change this to your IP for security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-windows-hosts-sg"
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Random password for ansible user
resource "random_password" "ansible_user" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Secrets Manager secret for ansible user password
resource "aws_secretsmanager_secret" "ansible_password" {
  name = "${var.project_name}-ansible-password"
  description = "Random password for ansible user on control node"
}

resource "aws_secretsmanager_secret_version" "ansible_password" {
  secret_id     = aws_secretsmanager_secret.ansible_password.id
  secret_string = random_password.ansible_user.result
}

# EC2 Module - Instances
module "ec2" {
  source = "./modules/ec2"

  instance_type        = var.instance_type
  subnet_id            = aws_subnet.public.id
  control_node_sg_id   = aws_security_group.control_node.id
  linux_hosts_sg_id    = aws_security_group.linux_hosts.id
  windows_hosts_sg_id  = aws_security_group.windows_hosts.id
  project_name         = var.project_name
  ubuntu_ami_owner     = var.ubuntu_ami_owner
  windows_ami_owner    = var.windows_ami_owner
  ansible_password_secret_name = aws_secretsmanager_secret.ansible_password.name
}
