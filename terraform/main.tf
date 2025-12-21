# Look up existing VPC by CIDR if it exists and we're not reusing provided IDs
data "aws_vpc" "existing" {
  count = var.use_existing_network || var.create_vpc ? 0 : 1
  
  filter {
    name   = "cidr"
    values = [var.vpc_cidr]
  }
  
  filter {
    name   = "tag:Name"
    values = ["${var.project_name}-vpc"]
  }
}

# VPC - only create if create_vpc is true and not reusing network
resource "aws_vpc" "main" {
  count = var.use_existing_network ? 0 : (var.create_vpc ? 1 : 0)
  
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

locals {
  vpc_id = var.use_existing_network ? var.existing_vpc_id : (var.create_vpc ? aws_vpc.main[0].id : data.aws_vpc.existing[0].id)
}

# Internet Gateway - look up or create
data "aws_internet_gateway" "existing" {
  count = var.use_existing_network || var.create_vpc ? 0 : 1
  
  filter {
    name   = "attachment.vpc-id"
    values = [local.vpc_id]
  }
}

resource "aws_internet_gateway" "main" {
  count  = var.use_existing_network ? 0 : (var.create_vpc ? 1 : 0)
  vpc_id = local.vpc_id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

locals {
  igw_id = var.use_existing_network ? null : (var.create_vpc ? aws_internet_gateway.main[0].id : data.aws_internet_gateway.existing[0].id)
}

# Public Subnet
resource "aws_subnet" "public" {
  count                   = var.use_existing_network ? 0 : 1
  vpc_id                  = local.vpc_id
  cidr_block              = var.subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-subnet"
  }
}

# Route Table
resource "aws_route_table" "public" {
  count = var.use_existing_network ? 0 : 1
  vpc_id = local.vpc_id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = local.igw_id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  count          = var.use_existing_network ? 0 : 1
  subnet_id      = aws_subnet.public[0].id
  route_table_id = aws_route_table.public[0].id
}

locals {
  subnet_id = var.use_existing_network ? var.existing_subnet_id : aws_subnet.public[0].id
}

# Security Group for Ansible Control Node
resource "aws_security_group" "control_node" {
  count       = var.use_existing_security_groups ? 0 : 1
  name        = "${var.project_name}-${var.environment}-control-node-sg"
  description = "Security group for Ansible control node"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Change this to your IP for security
  }

  # Semaphore web UI port (always open for potential Semaphore nodes)
  ingress {
    from_port   = 3000
    to_port     = 3000
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
    Name = "${var.project_name}-${var.environment}-control-node-sg"
  }
}

# Security Group for Linux Hosts
resource "aws_security_group" "linux_hosts" {
  count       = var.use_existing_security_groups ? 0 : 1
  name        = "${var.project_name}-${var.environment}-linux-hosts-sg"
  description = "Security group for Linux managed hosts"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.control_node[0].id]
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
    Name = "${var.project_name}-${var.environment}-linux-hosts-sg"
  }
}

# Security Group for Windows Hosts
resource "aws_security_group" "windows_hosts" {
  count       = var.use_existing_security_groups ? 0 : 1
  name        = "${var.project_name}-${var.environment}-windows-hosts-sg"
  description = "Security group for Windows managed hosts"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 5985
    to_port         = 5986
    protocol        = "tcp"
    security_groups = [aws_security_group.control_node[0].id]
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
    Name = "${var.project_name}-${var.environment}-windows-hosts-sg"
  }
}

locals {
  control_node_sg_id  = var.use_existing_security_groups ? var.existing_control_node_sg_id  : try(aws_security_group.control_node[0].id, null)
  linux_hosts_sg_id   = var.use_existing_security_groups ? var.existing_linux_hosts_sg_id   : try(aws_security_group.linux_hosts[0].id, null)
  windows_hosts_sg_id = var.use_existing_security_groups ? var.existing_windows_hosts_sg_id : try(aws_security_group.windows_hosts[0].id, null)
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Random password for ansible user
resource "random_password" "ansible_user" {
  count   = var.create_ansible_secret ? 1 : 0
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# Secrets Manager secret for ansible user password
resource "aws_secretsmanager_secret" "ansible_password" {
  count = var.create_ansible_secret ? 1 : 0
  name = "${var.project_name}-${var.environment}-ansible-password"
  description = "Random password for ansible user on control node"
}

resource "aws_secretsmanager_secret_version" "ansible_password" {
  count         = var.create_ansible_secret ? 1 : 0
  secret_id     = aws_secretsmanager_secret.ansible_password[0].id
  secret_string = random_password.ansible_user[0].result
}

# EC2 Module - Instances
module "ec2" {
  source = "./modules/ec2"

  instance_type        = var.instance_type
  subnet_id            = local.subnet_id
  control_node_sg_id   = local.control_node_sg_id
  linux_hosts_sg_id    = local.linux_hosts_sg_id
  windows_hosts_sg_id  = local.windows_hosts_sg_id
  project_name         = var.project_name
  environment          = var.environment
  associate_public_ip_address = var.associate_public_ip_address
  ubuntu_ami_owner     = var.ubuntu_ami_owner
  windows_ami_owner    = var.windows_ami_owner
  ansible_password_secret_name = var.create_ansible_secret ? aws_secretsmanager_secret.ansible_password[0].name : var.ansible_password_secret_name_override

  create_control_node  = var.create_control_node
  create_host1_linux   = var.create_host1_linux
  create_host2_windows = var.create_host2_windows
}
