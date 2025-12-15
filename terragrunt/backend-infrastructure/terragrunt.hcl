# Backend infrastructure uses local state (creates the remote state bucket)
# Don't include root configuration to avoid remote state chicken-and-egg problem

terraform {
  source = "${get_parent_terragrunt_dir()}/../../terraform/backend-infrastructure"
}

inputs = {
  aws_region   = "us-east-1"
  project_name = "ansible-poc"
  environment  = "backend"
}
