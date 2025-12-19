variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "subnet_id" {
  description = "Subnet ID for instances"
  type        = string
}

variable "control_node_sg_id" {
  description = "Security group ID for control node"
  type        = string
}

variable "linux_hosts_sg_id" {
  description = "Security group ID for Linux hosts"
  type        = string
}

variable "windows_hosts_sg_id" {
  description = "Security group ID for Windows hosts"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "ansible-poc"
}

variable "ubuntu_ami_owner" {
  description = "Owner of Ubuntu AMI"
  type        = string
  default     = "099720109477"
}

variable "windows_ami_owner" {
  description = "Owner of Windows AMI"
  type        = string
  default     = "801119661308"
}

variable "ansible_password_secret_name" {
  description = "Name of the Secrets Manager secret containing ansible user password"
  type        = string
}
