# Ansible PoC - Project Summary

## Project Overview

This is a complete **Infrastructure as Code (IaC)** solution for deploying an Ansible Proof of Concept lab on AWS. It combines **Terraform** for infrastructure definition, **Terragrunt** for managing multiple environments, and **GitHub Actions** for CI/CD automation.

## What's Included

### Infrastructure Components

✅ **VPC & Networking**
- VPC with CIDR block 10.0.0.0/16
- Public subnet 10.0.1.0/24
- Internet Gateway for public access
- Route tables and associations

✅ **Security Groups**
- Control Node SG (SSH access)
- Linux Hosts SG (SSH from control node or external)
- Windows Hosts SG (WinRM from control node, RDP for management)

✅ **3 EC2 Instances** (all t2.micro)
- **Control Node**: Ubuntu 24.04 with Ansible pre-installed
- **Linux Host**: Ubuntu 24.04 ready for Ansible management
- **Windows Host**: Windows Server 2022 with WinRM configured

✅ **State Management**
- S3 bucket with versioning and encryption for Terraform state
- DynamoDB table for distributed state locking
- Prevents concurrent modifications and state corruption

✅ **CI/CD Pipelines**
- **Plan Workflow**: Validates changes on pull requests
- **Apply Workflow**: Deploys infrastructure on pushes to main
- OIDC-based AWS authentication (no long-lived credentials)

### Key Features

| Feature | Details |
|---------|---------|
| **IaC Tool** | Terraform 1.6+ |
| **Configuration Management** | Terragrunt for DRY configurations |
| **AWS Region** | us-east-1 (configurable) |
| **Instance Type** | t2.micro (AWS free tier eligible) |
| **State Backend** | S3 + DynamoDB (single AWS account) |
| **CI/CD Platform** | GitHub Actions |
| **Authentication** | AWS IAM OIDC (secure, no credentials storage) |
| **Module Structure** | EC2 module for instance management |

## Directory Structure

```
ansible-demo/
├── .github/workflows/
│   ├── plan.yml              # Terraform plan on PRs
│   └── apply.yml             # Terraform apply on main branch
├── terraform/
│   ├── main.tf               # VPC, subnets, security groups
│   ├── variables.tf          # Input variables
│   ├── outputs.tf            # Output values
│   ├── provider.tf           # AWS provider config
│   ├── backend-infrastructure/
│   │   ├── main.tf          # S3 + DynamoDB
│   │   ├── variables.tf
│   │   └── provider.tf
│   └── modules/ec2/
│       ├── main.tf          # EC2 instances
│       ├── variables.tf
│       ├── outputs.tf
│       ├── user_data_control.sh    # Control node setup
│       ├── user_data_linux.sh      # Linux host setup
│       └── user_data_windows.ps1   # Windows host setup
├── terragrunt/
│   ├── terragrunt.hcl        # Root config (remote state)
│   ├── backend-infrastructure/
│   │   └── terragrunt.hcl    # Backend deployment config
│   └── dev/
│       └── terragrunt.hcl    # Dev environment config
├── docs/
│   ├── AWS_IAM_SETUP.md      # GitHub Actions OIDC setup
│   ├── LOCAL_DEVELOPMENT.md  # Local dev environment
│   └── ANSIBLE_NEXT_STEPS.md # Ansible configuration guide
├── README.md                  # Comprehensive documentation
├── QUICKSTART.md             # Fast deployment guide
├── .gitignore                # Git ignore rules
└── LICENSE                   # Project license
```

## Deployment Flow

### Local Deployment (Manual)

```
1. Configure AWS credentials
   └─ aws configure

2. Deploy Backend Infrastructure
   └─ cd terragrunt/backend-infrastructure
      ├─ terragrunt init
      ├─ terragrunt plan
      └─ terragrunt apply
      
   Creates: S3 bucket + DynamoDB table

3. Deploy Development Infrastructure
   └─ cd terragrunt/dev
      ├─ terragrunt init
      ├─ terragrunt plan
      └─ terragrunt apply
      
   Creates: VPC, subnets, security groups, 3 EC2 instances

4. Access Control Node
   └─ ssh -i keypair.pem ubuntu@<public-ip>

5. Configure Ansible
   └─ Set up inventory and test connectivity
```

### GitHub Actions Deployment (Automated)

```
1. Setup AWS IAM OIDC Provider
   └─ Create identity provider + role
      
2. Add GitHub Secrets
   └─ AWS_ROLE_TO_ASSUME = role ARN

3. Push to Main Branch
   └─ Triggers: apply.yml workflow
      ├─ Backend infrastructure (sequential)
      ├─ Development infrastructure (sequential)
      └─ Post deployment status

4. Create Pull Requests
   └─ Triggers: plan.yml workflow
      ├─ Validates changes
      ├─ Comments with plan summary
      └─ No deployment until merged
```

## Getting Started

### Option 1: Quick Local Deployment (5-10 minutes)

```bash
# 1. Configure AWS
aws configure

# 2. Deploy backend
cd terragrunt/backend-infrastructure
terragrunt apply

# 3. Deploy infrastructure
cd ../dev
terragrunt apply

# 4. Get outputs
terragrunt output

# 5. SSH to control node
ssh -i keypair.pem ubuntu@<ip>
```

See: [QUICKSTART.md](QUICKSTART.md)

### Option 2: GitHub Actions Deployment

```bash
# 1. Complete AWS IAM setup
# See: docs/AWS_IAM_SETUP.md

# 2. Push to repository
git push origin main

# 3. Monitor GitHub Actions
# Workflows tab → follow apply workflow
```

### Option 3: Hybrid Approach (Recommended)

```bash
# 1. Deploy locally for testing
terragrunt apply

# 2. Test Ansible setup
ansible all -m ping

# 3. Commit and push
git add .
git commit -m "Infrastructure deployment"
git push origin main

# 4. Future changes via GitHub Actions
# Create PR → plan workflow validates
# Merge PR → apply workflow deploys
```

## Configuration Options

### Change AWS Region

Edit `terragrunt/terragrunt.hcl`:
```hcl
locals {
  aws_region = "us-west-2"  # Change this
}
```

### Change Instance Type

Edit `terragrunt/dev/terragrunt.hcl`:
```hcl
inputs = {
  instance_type = "t2.small"  # Change from t2.micro
}
```

### Change VPC CIDR

Edit `terragrunt/dev/terragrunt.hcl`:
```hcl
inputs = {
  vpc_cidr    = "172.16.0.0/16"
  subnet_cidr = "172.16.1.0/24"
}
```

### Add More Instances

Modify `terraform/modules/ec2/main.tf` to add more `aws_instance` resources.

## Security Considerations

⚠️ **Before Production Use:**

1. **Restrict SSH Access**: Replace `0.0.0.0/0` with your IP in security groups
2. **Windows Password**: Change default `AnsibleUser@123!` in `user_data_windows.ps1`
3. **Enable Encryption**: S3 is encrypted, but consider KMS keys for sensitive data
4. **IAM Permissions**: Use least-privilege approach for GitHub Actions role
5. **Network**: Consider using private subnets and bastion hosts
6. **Monitoring**: Enable CloudWatch and VPC Flow Logs

## Terraform State Management

The solution uses **remote state** for safety:

- **Location**: S3 bucket (encrypted, versioned)
- **Locking**: DynamoDB table (prevents concurrent modifications)
- **Benefits**:
  - Team collaboration
  - State history preserved
  - Automatic backups
  - Prevents race conditions

## GitHub Actions Workflows

### Plan Workflow (`.github/workflows/plan.yml`)

**Trigger**: Pull Requests, Manual trigger

**Steps**:
1. Checks out code
2. Sets up Terraform & Terragrunt
3. Authenticates to AWS via OIDC
4. Runs plan for each environment
5. Uploads artifacts
6. Comments on PR with results

**Purpose**: Validate changes before merging

### Apply Workflow (`.github/workflows/apply.yml`)

**Trigger**: Pushes to `main`, Manual trigger

**Steps**:
1. Checks out code
2. Sets up Terraform & Terragrunt
3. Authenticates to AWS via OIDC
4. Deploys backend infrastructure first
5. Deploys dev infrastructure second
6. Exports outputs as artifacts
7. Posts deployment status

**Purpose**: Automatically deploy approved changes

## Next Steps

### 1. Deploy Infrastructure
- Follow [QUICKSTART.md](QUICKSTART.md) for local deployment
- Or complete [AWS IAM Setup](docs/AWS_IAM_SETUP.md) for GitHub Actions

### 2. Configure Ansible
- SSH to control node
- Follow [ANSIBLE_NEXT_STEPS.md](docs/ANSIBLE_NEXT_STEPS.md)
- Test connectivity to all hosts
- Create your first playbooks

### 3. Expand the Setup
- Add more EC2 instances
- Create multiple environments (dev, staging, prod)
- Add RDS database or other resources
- Implement monitoring and logging

### 4. Integrate with CI/CD
- Automate Ansible playbook execution
- Add configuration management to pipelines
- Implement automated testing

## Documentation Files

| File | Purpose |
|------|---------|
| [README.md](README.md) | Comprehensive project documentation |
| [QUICKSTART.md](QUICKSTART.md) | Fast deployment guide |
| [docs/AWS_IAM_SETUP.md](docs/AWS_IAM_SETUP.md) | GitHub Actions OIDC configuration |
| [docs/LOCAL_DEVELOPMENT.md](docs/LOCAL_DEVELOPMENT.md) | Local development environment setup |
| [docs/ANSIBLE_NEXT_STEPS.md](docs/ANSIBLE_NEXT_STEPS.md) | Ansible configuration and playbooks |

## Cost Estimation

Using **AWS Free Tier** (eligible):
- EC2 instances (t2.micro): ~750 hours/month free
- S3 storage: 5GB free
- DynamoDB: Pay-per-request (minimal for this setup)
- Data transfer: 1GB/month free outbound

**Estimated monthly cost**: FREE (within free tier limits)

⚠️ **Note**: Charges apply if instances run beyond free tier hours or other services are used.

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| State bucket doesn't exist | Deploy backend infrastructure first |
| Access Denied errors | Verify AWS credentials: `aws sts get-caller-identity` |
| SSH access denied | Check security group allows port 22 |
| Slow Windows initialization | Normal, takes 10-15 minutes after creation |
| Terraform lock timeout | Check/remove lock from DynamoDB table |
| GitHub Actions auth failure | Verify OIDC setup and role ARN in secrets |

See [docs/LOCAL_DEVELOPMENT.md](docs/LOCAL_DEVELOPMENT.md) for more troubleshooting.

## Key Technologies

- **Terraform 1.6+**: Infrastructure definition and management
- **Terragrunt 0.54+**: Terraform configuration management
- **AWS**: Cloud infrastructure provider
- **GitHub Actions**: CI/CD automation
- **Ansible**: Configuration management (pre-installed on control node)
- **Bash/PowerShell**: Instance initialization scripts

## Project Phases

### Phase 1 ✅ (Complete)
- Infrastructure as Code setup
- Terraform/Terragrunt configuration
- GitHub Actions workflows
- Backend state management

### Phase 2 (Next)
- Ansible inventory configuration
- Basic playbooks for system updates
- Configuration management for all hosts

### Phase 3 (Future)
- Production-grade security hardening
- Multi-environment setup (dev, staging, prod)
- Advanced Ansible roles and playbooks
- Monitoring and logging integration
- Auto-scaling policies

## Support & Resources

### Official Documentation
- [Terraform](https://www.terraform.io/docs)
- [Terragrunt](https://terragrunt.gruntwork.io/docs/)
- [Ansible](https://docs.ansible.com/)
- [GitHub Actions](https://docs.github.com/en/actions)

### AWS Services
- [EC2](https://docs.aws.amazon.com/ec2/)
- [VPC](https://docs.aws.amazon.com/vpc/)
- [S3](https://docs.aws.amazon.com/s3/)
- [DynamoDB](https://docs.aws.amazon.com/dynamodb/)

## License

See [LICENSE](LICENSE) file for details.

## Summary

This project provides a **production-ready framework** for:
- ✅ Deploying infrastructure via code (IaC)
- ✅ Managing state safely and securely
- ✅ Automating deployments with GitHub Actions
- ✅ Managing 3 EC2 instances (Linux + Windows)
- ✅ Setting up Ansible for configuration management

**Start with**: [QUICKSTART.md](QUICKSTART.md)

**For details**: [README.md](README.md)

**For Ansible setup**: [docs/ANSIBLE_NEXT_STEPS.md](docs/ANSIBLE_NEXT_STEPS.md)
