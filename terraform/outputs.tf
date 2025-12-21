output "vpc_id" {
  description = "VPC ID"
  value       = local.vpc_id
}

output "subnet_id" {
  description = "Public subnet ID"
  value       = local.subnet_id
}

output "control_node_sg_id" {
  description = "Control node security group ID"
  value       = local.control_node_sg_id
}

output "linux_hosts_sg_id" {
  description = "Linux hosts security group ID"
  value       = local.linux_hosts_sg_id
}

output "windows_hosts_sg_id" {
  description = "Windows hosts security group ID"
  value       = local.windows_hosts_sg_id
}

output "ansible_password_secret_name" {
  description = "Secret name containing the ansible user password"
  value       = var.create_ansible_secret ? aws_secretsmanager_secret.ansible_password[0].name : var.ansible_password_secret_name_override
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

output "host1_linux_private_ip" {
  description = "Linux host 1 private IP"
  value       = module.ec2.host1_linux_private_ip
}

output "host2_windows_id" {
  description = "Windows host 2 instance ID"
  value       = module.ec2.host2_windows_id
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
