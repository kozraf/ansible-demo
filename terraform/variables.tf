variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "ansible-poc"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "create_vpc" {
  description = "Whether to create a new VPC or use existing one"
  type        = bool
  default     = true
}

variable "use_existing_network" {
  description = "Reuse existing VPC and subnet instead of creating new ones"
  type        = bool
  default     = false
}

variable "existing_vpc_id" {
  description = "Existing VPC ID to reuse when use_existing_network is true"
  type        = string
  default     = ""
  validation {
    condition     = var.use_existing_network == false || length(var.existing_vpc_id) > 0
    error_message = "Provide existing_vpc_id when use_existing_network is true."
  }
}

variable "existing_subnet_id" {
  description = "Existing subnet ID to reuse when use_existing_network is true"
  type        = string
  default     = ""
  validation {
    condition     = var.use_existing_network == false || length(var.existing_subnet_id) > 0
    error_message = "Provide existing_subnet_id when use_existing_network is true."
  }
}

variable "use_existing_security_groups" {
  description = "Reuse existing security groups (control/linux/windows) instead of creating new ones"
  type        = bool
  default     = false
}

variable "existing_control_node_sg_id" {
  description = "Existing control node security group ID"
  type        = string
  default     = ""
}

variable "existing_linux_hosts_sg_id" {
  description = "Existing linux hosts security group ID"
  type        = string
  default     = ""
}

variable "existing_windows_hosts_sg_id" {
  description = "Existing windows hosts security group ID"
  type        = string
  default     = ""
}

variable "create_ansible_secret" {
  description = "Whether to create a new Secrets Manager secret for the ansible user password"
  type        = bool
  default     = true
}

variable "ansible_password_secret_name_override" {
  description = "Override secret name when not creating a new one (reuse from another stack)"
  type        = string
  default     = ""
}

variable "subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "create_control_node" {
  description = "Whether to create the control/semaphore node"
  type        = bool
  default     = true
}

variable "create_host1_linux" {
  description = "Whether to create the Linux managed host"
  type        = bool
  default     = true
}

variable "create_host2_windows" {
  description = "Whether to create the Windows managed host"
  type        = bool
  default     = true
}

variable "ubuntu_ami_owner" {
  description = "Owner of Ubuntu AMI"
  type        = string
  default     = "099720109477" # Canonical
}

variable "windows_ami_owner" {
  description = "Owner of Windows AMI"
  type        = string
  default     = "801119661308" # Amazon Windows AMIs
}

variable "associate_public_ip_address" {
  description = "Whether to associate public IP addresses with instances"
  type        = bool
  default     = true
}
