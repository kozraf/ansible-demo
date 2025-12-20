include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir()}/../terraform"
}

inputs = {
  environment           = "semaphore"
  vpc_cidr             = "10.1.0.0/16"
  public_subnet_cidr   = "10.1.1.0/24"
  private_subnet_cidr  = "10.1.2.0/24"
  
  # Semaphore server configuration
  control_node_count   = 1
  control_node_type    = "t3.small"  # Semaphore needs more resources
  
  # No managed nodes in this environment
  linux_node_count     = 0
  windows_node_count   = 0
  
  # Semaphore needs public IP for web UI access
  associate_public_ip_address = true
  
  # Tags
  project_name = "ansible-poc"
}
