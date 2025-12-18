# Ansible PoC - Infrastructure as Code

A complete Infrastructure as Code (IaC) solution for deploying an Ansible Proof of Concept lab on AWS using Terraform, Terragrunt, and GitHub Actions.

## Architecture Overview

This solution deploys the following infrastructure in AWS:

- **VPC**: 10.0.0.0/16 CIDR block
- **Public Subnet**: 10.0.1.0/24 for all instances
- **3 EC2 Instances** (all t2.micro):
  - **Control Node**: Ubuntu 24.04 LTS (Ansible control machine)
  - **Host 1 (Linux)**: Ubuntu 24.04 LTS (managed by Ansible)
  - **Host 2 (Windows)**: Windows Server 2022 (managed by Ansible via WinRM)
- **Security Groups**: Separate groups for control node, Linux hosts, and Windows hosts
- **Backend State Storage**:
  - **S3 Bucket**: For storing Terraform state files with versioning and encryption
  - **DynamoDB Table**: For state locking to prevent concurrent modifications

## Prerequisites

### Local Development

1. **AWS Account**: You need an AWS account with appropriate credentials
2. **Terraform**: Version 1.0+ (managed by GitHub Actions)
3. **Terragrunt**: Version 0.54.0+ (managed by GitHub Actions)
4. **AWS CLI**: For local testing (optional)
5. **Git**: For version control

### GitHub Actions Setup

1. **AWS IAM Role**: Create an IAM role for GitHub Actions OIDC authentication
2. **GitHub Secrets**: Configure `AWS_ROLE_TO_ASSUME` in repository secrets

## Directory Structure

```
.
├── .github/
│   └── workflows/
│       ├── plan.yml          # Plan workflow (runs on PRs)
│       └── apply.yml         # Apply workflow (runs on main branch pushes)
├── terraform/
│   ├── main.tf               # VPC, subnets, security groups
│   ├── provider.tf           # AWS provider configuration
│   ├── variables.tf          # Input variables
│   ├── outputs.tf            # Output values
│   ├── backend-infrastructure/  # S3 and DynamoDB setup
│   │   ├── main.tf
│   │   ├── provider.tf
│   │   └── variables.tf
│   └── modules/
│       └── ec2/              # EC2 instances module
│           ├── main.tf
│           ├── variables.tf
│           ├── outputs.tf
│           ├── user_data_control.sh
│           ├── user_data_linux.sh
│           └── user_data_windows.ps1
└── terragrunt/
    ├── terragrunt.hcl        # Root configuration with remote state
    ├── backend-infrastructure/
    │   └── terragrunt.hcl    # Backend infrastructure config
    └── dev/
        └── terragrunt.hcl    # Development environment config
```

## Deployment Steps

### Step 1: Deploy Backend Infrastructure

The backend infrastructure (S3 and DynamoDB) must be deployed first to store Terraform state.

```bash
cd terragrunt/backend-infrastructure
terragrunt init
terragrunt plan
terragrunt apply
```

This will create:
- S3 bucket: `ansible-poc-tf-state-<account-id>`
- DynamoDB table: `ansible-poc-tf-locks`

### Step 2: Deploy Main Infrastructure

After the backend is ready, deploy the main infrastructure:

```bash
cd terragrunt/dev
terragrunt init
terragrunt plan
terragrunt apply
```

This will create:
- VPC with public subnet
- Internet Gateway
- Route tables and security groups
- 3 EC2 instances with user data scripts

### Step 3: Access the Instances

After deployment, you can access the instances:

```bash
# Get outputs
terragrunt output -json

# SSH to control node
ssh -i <key-pair> ubuntu@<control-node-public-ip>

# SSH to Linux host
ssh -i <key-pair> ubuntu@<host1-public-ip>

# RDP to Windows host
mstsc /v:<host2-public-ip>
# Username: ansible
# Password: AnsibleUser@123! (change in production)

## Session Manager Access (Recommended)

Both Linux instances (control-node and host1-linux) support AWS Session Manager for secure, keyless access:

```bash
# Connect to control node
aws ssm start-session --target <control-node-instance-id>

# Connect to Linux host
aws ssm start-session --target <host1-linux-instance-id>
```

**Benefits:**
- No SSH keys required
- Secure connection through AWS
- Works from anywhere with AWS credentials
- Audit trail in CloudTrail
```

## GitHub Actions Workflows

### Plan Workflow (`.github/workflows/plan.yml`)

**Triggers**: Pull Requests, Manual trigger (workflow_dispatch)

**What it does**:
1. Checks out code
2. Sets up Terraform and Terragrunt
3. Configures AWS credentials using OIDC
4. Runs `terragrunt init` and `terragrunt plan`
5. Uploads plan artifacts
6. Comments on PR with plan summary

**Usage**: Create a PR with changes to `terraform/` or `terragrunt/` directories to trigger the workflow.

### Apply Workflow (`.github/workflows/apply.yml`)

**Triggers**: Pushes to `main` branch, Manual trigger (workflow_dispatch)

**What it does**:
1. Checks out code
2. Sets up Terraform and Terragrunt
3. Configures AWS credentials using OIDC
4. Deploys backend infrastructure first
5. Deploys main infrastructure second (sequential with `max-parallel: 1`)
6. Exports outputs as artifacts
7. Posts deployment status to PR/commit

**Usage**: Merge PRs to `main` branch to trigger deployment.

## Important Configuration Details

### Security Groups

- **Control Node**: Allows inbound SSH (22) from 0.0.0.0/0
- **Linux Hosts**: Allow inbound SSH (22) from control node or 0.0.0.0/0
- **Windows Hosts**: Allow inbound WinRM (5985-5986) from control node, RDP (3389) from 0.0.0.0/0

⚠️ **Security Note**: Replace `0.0.0.0/0` with your specific IP/CIDR blocks for production.

### User Data Scripts

#### Control Node (Ubuntu)
- Updates system packages
- Installs Ansible and dependencies (python3, pip, git, curl)
- Creates `ansible` user with SSH key pair
- Creates `/home/ansible/playbooks` and `/home/ansible/inventory` directories

#### Linux Host (Ubuntu)
- Updates system packages
- Installs Python and SSH prerequisites
- Creates `ansible` user with sudo privileges
- Prepares for Ansible management

#### Windows Host (Windows Server 2022)
- Enables WinRM for Ansible management
- Configures Basic authentication
- Creates `ansible` user with admin privileges
- Installs Python 3.11 and `pywinrm` module

### Terraform State Management

State is managed remotely on AWS:

```hcl
backend "s3" {
  bucket         = "ansible-poc-tf-state-<account-id>"
  key            = "terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "ansible-poc-tf-locks"
  encrypt        = true
}
```

This ensures:
- State is encrypted at rest
- Multiple concurrent modifications are prevented via DynamoDB locking
- State history is preserved with S3 versioning
- Public access is blocked

## AWS Authentication (GitHub Actions)

This setup uses AWS IAM roles with OIDC (OpenID Connect) for secure GitHub Actions authentication without storing long-lived credentials.

### Setup Instructions

1. Create an IAM OIDC identity provider:
```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aca1
```

2. Create an IAM role with the following trust policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:<github-org>/<repo-name>:*"
        }
      }
    }
  ]
}
```

3. Attach a policy that allows Terraform operations (S3, EC2, VPC, DynamoDB, etc.)

4. Add the role ARN to GitHub repository secrets as `AWS_ROLE_TO_ASSUME`

## Local Testing

### Initialize Terragrunt

```bash
cd terragrunt/backend-infrastructure
terragrunt init
```

### Plan Changes

```bash
cd terragrunt/dev
terragrunt plan
```

### Validate Configuration

```bash
cd terragrunt/dev
terragrunt validate
```

### View Outputs

```bash
cd terragrunt/dev
terragrunt output
```

## Customization

### Change AWS Region

Update in `terragrunt/terragrunt.hcl`:
```hcl
locals {
  aws_region = "us-west-2"  # Change this
}
```

### Change Instance Type

Update in `terragrunt/dev/terragrunt.hcl`:
```hcl
inputs = {
  instance_type = "t2.small"  # Change from t2.micro
}
```

### Change VPC CIDR

Update in `terragrunt/dev/terragrunt.hcl`:
```hcl
inputs = {
  vpc_cidr    = "172.16.0.0/16"
  subnet_cidr = "172.16.1.0/24"
}
```

### Modify Security Groups

Edit `terraform/main.tf` to adjust ingress/egress rules for each security group.

## Cleanup

To destroy all resources:

```bash
# Destroy dev infrastructure first
cd terragrunt/dev
terragrunt destroy

# Then destroy backend infrastructure
cd terragrunt/backend-infrastructure
terragrunt destroy
```

⚠️ **Warning**: This will delete all resources including the S3 bucket and DynamoDB table. Make sure you have no critical data stored there.

## Troubleshooting

### State Lock Issues

If Terraform is stuck on a lock:
```bash
aws dynamodb scan --table-name ansible-poc-tf-locks --region us-east-1
aws dynamodb delete-item --table-name ansible-poc-tf-locks \
  --key '{"LockID":{"S":"<lock-id>"}}' --region us-east-1
```

### SSH Access Issues

Ensure your security group allows SSH and you're using the correct key pair:
```bash
ssh -i /path/to/key.pem -v ubuntu@<ip>
```

### Windows RDP Issues

Wait 5-10 minutes after instance creation for Windows user data to complete. Check instance system logs in AWS console.

## Next Steps - Ansible Configuration

Once the infrastructure is deployed, you can:

1. SSH into the control node
2. Configure the Ansible inventory with the private IPs of managed hosts
3. Set up SSH key-based authentication for Linux hosts
4. Configure Ansible for Windows hosts (using the `ansible` user and password)
5. Create and run your first playbooks

Example inventory file on control node:
```ini
[linux]
host1 ansible_host=10.0.1.x ansible_user=ubuntu

[windows]
host2 ansible_host=10.0.1.y ansible_user=ansible ansible_password=AnsibleUser@123! ansible_connection=winrm
```

## Support and Contributions

For issues or improvements, please create a GitHub issue or submit a pull request.

## License

See LICENSE file for details.
