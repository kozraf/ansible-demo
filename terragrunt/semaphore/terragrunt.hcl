include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir()}/../terraform"
}

dependency "dev" {
  config_path = "../dev"

  mock_outputs = {
    vpc_id                 = "vpc-mock"
    subnet_id              = "subnet-mock"
    ansible_password_secret_name = "secret/mock"
  }
}

inputs = {
  environment           = "semaphore"
  vpc_cidr             = "10.0.0.0/16"  # Same VPC as dev
  subnet_cidr          = "10.0.3.0/24"  # Different subnet in same VPC
  create_vpc           = false          # Reuse dev's VPC
  use_existing_network = true
  existing_vpc_id      = dependency.dev.outputs.vpc_id
  existing_subnet_id   = dependency.dev.outputs.subnet_id
  
  # Create separate security groups for semaphore (not reusing dev's)
  use_existing_security_groups = false
  
  # Semaphore server configuration
  instance_type        = "t3.small"  # Semaphore needs more resources
  
  # Semaphore needs public IP for web UI access
  associate_public_ip_address = true

   # Only build the Semaphore control node here
   create_control_node  = true
   create_host1_linux   = false
   create_host2_windows = false

  # Reuse the ansible password secret from dev
  create_ansible_secret                 = false
  ansible_password_secret_name_override = dependency.dev.outputs.ansible_password_secret_name
  
  # Tags
  project_name = "ansible-poc"
}
