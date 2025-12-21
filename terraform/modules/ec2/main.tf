terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Get current AWS region
data "aws_region" "current" {}

# IAM Role for SSM
resource "aws_iam_role" "ssm_role" {
  name = "${var.project_name}-${var.environment}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ssm-role"
  }
}

# Attach SSM managed policy
resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach Secrets Manager policy
resource "aws_iam_role_policy" "secrets_manager_access" {
  name = "${var.project_name}-${var.environment}-secrets-manager-policy"
  role = aws_iam_role.ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:${var.ansible_password_secret_name}-*"
      }
    ]
  })
}

# Instance Profile
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.project_name}-${var.environment}-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

# Ubuntu 24 AMI for control node
data "aws_ami" "ubuntu_24" {
  most_recent = true
  owners      = [var.ubuntu_ami_owner]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Windows Server 2022 AMI
data "aws_ami" "windows_2022" {
  most_recent = true
  owners      = [var.windows_ami_owner]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Core-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Control Node - Ubuntu 24 (Can be Ansible Control or Semaphore Server)
resource "aws_instance" "control_node" {
  count                  = var.create_control_node ? 1 : 0
  ami                    = data.aws_ami.ubuntu_24.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.control_node_sg_id]
  associate_public_ip_address = var.associate_public_ip_address
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
  }

  user_data = base64encode(
    var.environment == "semaphore"
      ? templatefile("${path.module}/user_data_semaphore.sh", {
          ansible_password_secret_name = var.ansible_password_secret_name
          aws_region                   = data.aws_region.current.name
        })
      : file("${path.module}/user_data_control.sh")
  )

  tags = {
    Name = var.environment == "semaphore" ? "semaphore-server" : "control-node"
  }
}

# Linux Host 1 - Ubuntu 24
resource "aws_instance" "host1_linux" {
  count                  = var.create_host1_linux ? 1 : 0
  ami                    = data.aws_ami.ubuntu_24.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.linux_hosts_sg_id]
  associate_public_ip_address = false  # Managed host - no public IP needed
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
  }

  user_data = base64encode(file("${path.module}/user_data_linux.sh"))

  tags = {
    Name = "host1-linux"
  }
}

# Windows Host - Windows Server 2022
resource "aws_instance" "host2_windows" {
  count                  = var.create_host2_windows ? 1 : 0
  ami                    = data.aws_ami.windows_2022.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.windows_hosts_sg_id]
  associate_public_ip_address = false  # Managed host - no public IP needed
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
  }

  # Windows requires some setup for WinRM and Ansible
  user_data = base64encode(templatefile("${path.module}/user_data_windows.ps1", {
    ansible_user = "ansible"
  }))

  tags = {
    Name = "host2-win"
  }
}
