include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir()}/../terraform"
}

dependency "backend" {
  config_path = "../backend-infrastructure"
  
  mock_outputs = {
    s3_bucket_id      = "mock-bucket"
    dynamodb_table_id = "mock-table"
  }
}

inputs = {
  aws_region   = "us-east-1"
  environment  = "dev"
  project_name = "ansible-poc"
  vpc_cidr     = "10.0.0.0/16"
  subnet_cidr  = "10.0.1.0/24"
  instance_type = "t2.micro"
}
