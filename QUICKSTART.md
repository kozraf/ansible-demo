# Quick Start Guide

Get your Ansible PoC infrastructure up and running in minutes.

## Prerequisites

1. AWS Account with appropriate IAM permissions
2. Git repository set up (this repo)
3. GitHub repository (for Actions workflows)

## 5-Minute Setup

### 1. Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID and Secret Access Key
```

### 2. Deploy Backend Infrastructure

```bash
cd terragrunt/backend-infrastructure
terragrunt init
terragrunt apply
```

**What happens**: Creates S3 bucket and DynamoDB table for Terraform state.

### 3. Deploy Main Infrastructure

```bash
cd ../dev
terragrunt init
terragrunt apply
```

**What happens**: Creates VPC, subnets, security groups, and 3 EC2 instances.

**Wait time**: ~10-15 minutes for Windows instance to fully initialize.

### 4. Get Instance IPs

```bash
terragrunt output
```

Note the public IPs and private IPs from the output.

### 5. Access Control Node

**Option A: SSH (Traditional)**
```bash
ssh -i /path/to/keypair.pem ubuntu@<control-node-public-ip>
```

**Option B: AWS Session Manager (Recommended)**
```bash
# Connect via Session Manager (no SSH key needed)
aws ssm start-session --target <control-node-instance-id>
```

### 6. Access Linux Host via Session Manager

```bash
# Connect to Linux host via Session Manager
aws ssm start-session --target <host1-linux-instance-id>
```

Both Linux instances (control node and host1-linux) are configured with:
- SSM agent installed and running
- IAM role with SSM permissions attached
- Session Manager connectivity enabled

## Next: Configure Ansible

Once connected to the control node:

```bash
# Switch to ansible user
sudo su - ansible

# Configure inventory with your host IPs
vi ~/inventory/hosts

# Test connectivity
ansible -i ~/inventory/hosts all -m ping
```

For detailed instructions, see: [ANSIBLE_NEXT_STEPS.md](docs/ANSIBLE_NEXT_STEPS.md)

## GitHub Actions Setup (Optional)

1. Complete [AWS IAM Setup](docs/AWS_IAM_SETUP.md)
2. Add `AWS_ROLE_TO_ASSUME` secret to GitHub repository
3. Push changes to trigger workflows

## Cleanup

```bash
cd terragrunt/dev
terragrunt destroy

cd ../backend-infrastructure
terragrunt destroy
```

## Key Files

| File | Purpose |
|------|---------|
| `terragrunt/terragrunt.hcl` | Root configuration with remote state |
| `terragrunt/dev/terragrunt.hcl` | Dev environment variables |
| `terraform/main.tf` | VPC, subnets, security groups |
| `terraform/modules/ec2/` | EC2 instances module |
| `.github/workflows/plan.yml` | GitHub Actions plan workflow |
| `.github/workflows/apply.yml` | GitHub Actions apply workflow |

## Troubleshooting

**State bucket error**: Make sure backend infrastructure is deployed first.

**SSH access denied**: Verify security group allows SSH on port 22.

**Windows instance slow**: Normal, takes 10-15 minutes to initialize.

For more help, see: [LOCAL_DEVELOPMENT.md](docs/LOCAL_DEVELOPMENT.md)

## Architecture

```
┌─────────────────────────────────────────┐
│           AWS Account (us-east-1)       │
├─────────────────────────────────────────┤
│  ┌───────────────────────────────────┐  │
│  │      VPC (10.0.0.0/16)           │  │
│  │  ┌──────────────────────────────┐ │  │
│  │  │ Public Subnet (10.0.1.0/24)  │ │  │
│  │  │ ┌────────────┬────────────┬─┐ │  │
│  │  │ │ Control    │ Linux Host │W│ │  │
│  │  │ │ Node       │ (Ubuntu)   │i│ │  │
│  │  │ │ (Ubuntu)   │            │n│ │  │
│  │  │ │ t2.micro   │ t2.micro   │d│ │  │
│  │  │ │            │            │s│ │  │
│  │  │ │ Ansible    │ Managed by │ │ │  │
│  │  │ │ Installed  │ Ansible    │ │ │  │
│  │  │ └────────────┴────────────┴─┘ │  │
│  │  └──────────────────────────────┘ │  │
│  │              │                      │  │
│  │              └─ Internet Gateway    │  │
│  └───────────────────────────────────┘  │
│                                          │
│  ┌──────────────────┐  ┌──────────────┐ │
│  │  S3 Bucket       │  │  DynamoDB    │ │
│  │  (State)         │  │  (Locking)   │ │
│  └──────────────────┘  └──────────────┘ │
└─────────────────────────────────────────┘
```

## Support

- Terraform docs: https://www.terraform.io/docs
- Terragrunt docs: https://terragrunt.gruntwork.io/docs/
- Ansible docs: https://docs.ansible.com/
