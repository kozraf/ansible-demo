output "control_node_id" {
  description = "Control node instance ID"
  value       = aws_instance.control_node.id
}

output "control_node_public_ip" {
  description = "Control node public IP"
  value       = aws_instance.control_node.public_ip
}

output "control_node_private_ip" {
  description = "Control node private IP"
  value       = aws_instance.control_node.private_ip
}

output "host1_linux_id" {
  description = "Linux host 1 instance ID"
  value       = aws_instance.host1_linux.id
}

output "host1_linux_public_ip" {
  description = "Linux host 1 public IP"
  value       = aws_instance.host1_linux.public_ip
}

output "host1_linux_private_ip" {
  description = "Linux host 1 private IP"
  value       = aws_instance.host1_linux.private_ip
}

output "host2_windows_id" {
  description = "Windows host 2 instance ID"
  value       = aws_instance.host2_windows.id
}

output "host2_windows_public_ip" {
  description = "Windows host 2 public IP"
  value       = aws_instance.host2_windows.public_ip
}

output "host2_windows_private_ip" {
  description = "Windows host 2 private IP"
  value       = aws_instance.host2_windows.private_ip
}

output "ubuntu_ami_id" {
  description = "Ubuntu 24 AMI ID used"
  value       = data.aws_ami.ubuntu_24.id
}

output "windows_ami_id" {
  description = "Windows Server 2022 AMI ID used"
  value       = data.aws_ami.windows_2022.id
}
