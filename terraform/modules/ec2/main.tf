terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
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

# Control Node - Ubuntu 24
resource "aws_instance" "control_node" {
  ami                    = data.aws_ami.ubuntu_24.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.control_node_sg_id]
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
  }

  user_data = base64encode(file("${path.module}/user_data_control.sh"))

  tags = {
    Name = "control-node"
  }
}

# Linux Host 1 - Ubuntu 24
resource "aws_instance" "host1_linux" {
  ami                    = data.aws_ami.ubuntu_24.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.linux_hosts_sg_id]
  associate_public_ip_address = true

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
  ami                    = data.aws_ami.windows_2022.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.windows_hosts_sg_id]
  associate_public_ip_address = true

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

  depends_on = [aws_instance.control_node, aws_instance.host1_linux]
}
