output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "control_node_id" {
  description = "Ansible control node instance ID"
  value       = module.ec2.control_node_id
}

output "control_node_public_ip" {
  description = "Ansible control node public IP"
  value       = module.ec2.control_node_public_ip
}

output "control_node_private_ip" {
  description = "Ansible control node private IP"
  value       = module.ec2.control_node_private_ip
}

output "host1_linux_id" {
  description = "Linux host 1 instance ID"
  value       = module.ec2.host1_linux_id
}

output "host1_linux_public_ip" {
  description = "Linux host 1 public IP"
  value       = module.ec2.host1_linux_public_ip
}

output "host1_linux_private_ip" {
  description = "Linux host 1 private IP"
  value       = module.ec2.host1_linux_private_ip
}

output "host2_windows_id" {
  description = "Windows host 2 instance ID"
  value       = module.ec2.host2_windows_id
}

output "host2_windows_public_ip" {
  description = "Windows host 2 public IP"
  value       = module.ec2.host2_windows_public_ip
}

output "host2_windows_private_ip" {
  description = "Windows host 2 private IP"
  value       = module.ec2.host2_windows_private_ip
}

output "ubuntu_ami_id" {
  description = "Ubuntu 24 AMI ID used"
  value       = module.ec2.ubuntu_ami_id
}

output "windows_ami_id" {
  description = "Windows Server 2022 AMI ID used"
  value       = module.ec2.windows_ami_id
}
