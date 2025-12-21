output "control_node_id" {
  description = "Control node instance ID"
  value       = try(aws_instance.ansible_control_node[0].id, null)
}

output "semaphore_server_id" {
  description = "Semaphore server instance ID (alias for control_node_id)"
  value       = try(aws_instance.semaphore_server[0].id, null)
}

output "control_node_public_ip" {
  description = "Control node public IP"
  value       = try(aws_instance.ansible_control_node[0].public_ip, null)
}

output "semaphore_public_ip" {
  description = "Semaphore server public IP (alias for control_node_public_ip)"
  value       = try(aws_instance.semaphore_server[0].public_ip, null)
}

output "control_node_private_ip" {
  description = "Control node private IP"
  value       = try(aws_instance.ansible_control_node[0].private_ip, null)
}

output "semaphore_private_ip" {
  description = "Semaphore server private IP (alias for control_node_private_ip)"
  value       = try(aws_instance.semaphore_server[0].private_ip, null)
}

output "host1_linux_id" {
  description = "Linux host 1 instance ID"
  value       = try(aws_instance.host1_linux[0].id, null)
}

output "host1_linux_private_ip" {
  description = "Linux host 1 private IP"
  value       = try(aws_instance.host1_linux[0].private_ip, null)
}

output "host2_windows_id" {
  description = "Windows host 2 instance ID"
  value       = try(aws_instance.host2_windows[0].id, null)
}

output "host2_windows_private_ip" {
  description = "Windows host 2 private IP"
  value       = try(aws_instance.host2_windows[0].private_ip, null)
}

output "ubuntu_ami_id" {
  description = "Ubuntu 24 AMI ID used"
  value       = data.aws_ami.ubuntu_24.id
}

output "windows_ami_id" {
  description = "Windows Server 2022 AMI ID used"
  value       = data.aws_ami.windows_2022.id
}
