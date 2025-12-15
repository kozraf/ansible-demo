# Implementation Checklist

Use this checklist to track your progress through the Ansible PoC setup.

## Pre-Deployment Checklist

- [ ] AWS account created and accessible
- [ ] AWS credentials configured locally (`aws configure`)
- [ ] Git repository cloned locally
- [ ] Terraform installed (v1.6+)
- [ ] Terragrunt installed (v0.54+)
- [ ] SSH key pair created in AWS (or have existing one)
- [ ] GitHub repository created (if using GitHub Actions)

## Phase 1: Backend Infrastructure

### Local Deployment

- [ ] Verify AWS credentials: `aws sts get-caller-identity`
- [ ] Navigate to `terragrunt/backend-infrastructure`
- [ ] Run `terragrunt init`
- [ ] Review plan: `terragrunt plan`
- [ ] Deploy: `terragrunt apply`
- [ ] Verify S3 bucket created: `aws s3 ls`
- [ ] Verify DynamoDB table created: `aws dynamodb list-tables --region us-east-1`

## Phase 2: Development Infrastructure

### Local Deployment

- [ ] Navigate to `terragrunt/dev`
- [ ] Run `terragrunt init`
- [ ] Review plan: `terragrunt plan`
- [ ] Deploy: `terragrunt apply`
- [ ] Wait for instances to fully initialize (10-15 minutes)
- [ ] Get outputs: `terragrunt output`
- [ ] Document IP addresses:
  - [ ] Control Node Public IP: _______________
  - [ ] Control Node Private IP: _______________
  - [ ] Host1 Linux Public IP: _______________
  - [ ] Host1 Linux Private IP: _______________
  - [ ] Host2 Windows Public IP: _______________
  - [ ] Host2 Windows Private IP: _______________

### Verify Deployment

- [ ] Verify instances in AWS Console (EC2 → Instances)
- [ ] Verify VPC created: `aws ec2 describe-vpcs --region us-east-1`
- [ ] Verify security groups created: `aws ec2 describe-security-groups --region us-east-1`

## Phase 3: Control Node Access

### Initial Connection

- [ ] SSH to control node: `ssh -i <keypair> ubuntu@<control-ip>`
- [ ] Verify Ansible installed: `ansible --version`
- [ ] Switch to ansible user: `sudo su - ansible`
- [ ] Verify ansible directories exist: `ls -la ~/`
  - [ ] `~/playbooks/`
  - [ ] `~/inventory/`

## Phase 4: Ansible Configuration

### Inventory Setup

- [ ] Edit inventory file: `vi ~/inventory/hosts`
- [ ] Update Linux host IP: `10.0.1.x`
- [ ] Update Windows host IP: `10.0.1.y`
- [ ] Test inventory: `ansible-inventory --list`

### SSH Key Setup for Linux Host

- [ ] Generate SSH key (if not already done): `ssh-keygen -t rsa -b 4096`
- [ ] Get public key: `cat ~/.ssh/id_rsa.pub`
- [ ] Copy key to Linux host authorized_keys
- [ ] Test SSH access: `ssh ubuntu@10.0.1.x`

### Connectivity Testing

- [ ] Test Linux host ping: `ansible -i ~/inventory/hosts host1-linux -m ping`
- [ ] Expected output: `SUCCESS => { "ping": "pong" }`
- [ ] Test Windows host ping: `ansible -i ~/inventory/hosts host2-windows -m win_ping`
- [ ] Expected output: `SUCCESS => { "ping": "pong" }`
- [ ] Test all hosts: `ansible -i ~/inventory/hosts all -m ping`

## Phase 5: First Playbooks (Optional)

### Create and Run Playbooks

- [ ] Create playbooks directory: `mkdir -p ~/playbooks`
- [ ] Create Linux update playbook: `linux_update.yml`
- [ ] Create Windows check playbook: `windows_check.yml`
- [ ] Run Linux playbook: `ansible-playbook -i ~/inventory/hosts ~/playbooks/linux_update.yml`
- [ ] Run Windows playbook: `ansible-playbook -i ~/inventory/hosts ~/playbooks/windows_check.yml`
- [ ] Verify both playbooks executed successfully

## Phase 6: GitHub Actions Setup (Optional)

### AWS IAM Configuration

- [ ] Create OIDC identity provider in AWS
- [ ] Create IAM role for GitHub Actions
- [ ] Attach permissions policy to role
- [ ] Document role ARN: _______________

### GitHub Repository Configuration

- [ ] Push code to GitHub repository
- [ ] Add repository secret `AWS_ROLE_TO_ASSUME`
- [ ] Value: `arn:aws:iam::ACCOUNT:role/GitHubActionsAnsiblePoCRole`

### Workflow Testing

- [ ] Create test branch: `git checkout -b test/setup`
- [ ] Make minor change to `terraform/variables.tf`
- [ ] Push branch and create PR: `git push origin test/setup`
- [ ] Verify Plan workflow triggers in GitHub Actions
- [ ] Review plan output in workflow logs
- [ ] Merge PR to trigger Apply workflow
- [ ] Verify Apply workflow completes successfully

## Phase 7: Documentation & Handoff

### Documentation Updates

- [ ] Review `README.md` for completeness
- [ ] Update any environment-specific details
- [ ] Document your AWS account ID, region, and custom settings
- [ ] Document your GitHub Actions role ARN
- [ ] Update IP addresses in documentation

### Knowledge Transfer

- [ ] Team familiar with Terraform/Terragrunt structure
- [ ] Team familiar with GitHub Actions workflows
- [ ] Team aware of state management location (S3 + DynamoDB)
- [ ] Team trained on adding/removing instances
- [ ] Team trained on Ansible basics

## Post-Deployment Verification

### Infrastructure Health

- [ ] [ ] All 3 instances running in EC2 console
- [ ] [ ] VPC and subnets correctly configured
- [ ] [ ] Security groups have expected rules
- [ ] [ ] Internet Gateway attached to VPC
- [ ] [ ] Route table correctly configured

### Ansible Health

- [ ] [ ] Control node has Ansible installed
- [ ] [ ] Inventory file properly configured
- [ ] [ ] Can ping all managed hosts
- [ ] [ ] SSH keys working for Linux hosts
- [ ] [ ] WinRM working for Windows host

### State Management

- [ ] [ ] Terraform state stored in S3
- [ ] [ ] S3 bucket has versioning enabled
- [ ] [ ] S3 bucket is encrypted
- [ ] [ ] DynamoDB table exists for locking
- [ ] [ ] No local .tfstate files in repository

## Troubleshooting Checklist

If encountering issues:

- [ ] Check AWS credentials: `aws sts get-caller-identity`
- [ ] Verify Terragrunt version: `terragrunt --version`
- [ ] Verify Terraform version: `terraform version`
- [ ] Check backend state: `aws s3 ls` and `aws dynamodb list-tables`
- [ ] Review CloudFormation events (if applicable)
- [ ] Check EC2 instance system logs in AWS console
- [ ] Review GitHub Actions workflow logs
- [ ] Verify security group rules allow required ports
- [ ] Check SSH key pair is correct
- [ ] Verify AWS region matches configuration (us-east-1)

## Cleanup Checklist (When Ready to Destroy)

**⚠️ Warning: This is destructive and cannot be undone**

- [ ] Backup any important data
- [ ] Verify you want to delete all resources
- [ ] Confirm no production workloads running

### Destroy Order

1. [ ] Destroy dev infrastructure:
   ```bash
   cd terragrunt/dev
   terragrunt destroy
   ```

2. [ ] Destroy backend infrastructure:
   ```bash
   cd ../backend-infrastructure
   terragrunt destroy
   ```

3. [ ] Verify resources deleted:
   - [ ] EC2 instances terminated
   - [ ] VPC deleted
   - [ ] S3 bucket empty or deleted
   - [ ] DynamoDB table deleted

## Sign-Off

- [ ] Deployment completed successfully
- [ ] Ansible connectivity verified
- [ ] All documentation reviewed
- [ ] Team trained on infrastructure
- [ ] Backup/disaster recovery plan in place

**Deployment Date**: _______________

**Deployed By**: _______________

**Notes/Issues Encountered**:
```
_____________________________________________
_____________________________________________
_____________________________________________
```

## Quick Reference Commands

```bash
# AWS Verification
aws sts get-caller-identity
aws ec2 describe-instances --region us-east-1
aws s3 ls

# Terragrunt Deployment
cd terragrunt/backend-infrastructure && terragrunt apply
cd terragrunt/dev && terragrunt apply

# Terragrunt Information
terragrunt output
terragrunt state list
terragrunt validate

# Ansible Testing
ansible -i ~/inventory/hosts all -m ping
ansible-playbook -i ~/inventory/hosts ~/playbooks/linux_update.yml

# Cleanup (DESTRUCTIVE)
cd terragrunt/dev && terragrunt destroy
cd terragrunt/backend-infrastructure && terragrunt destroy
```

## Resources

- [QUICKSTART.md](QUICKSTART.md) - 5-minute deployment guide
- [README.md](README.md) - Comprehensive documentation
- [docs/LOCAL_DEVELOPMENT.md](docs/LOCAL_DEVELOPMENT.md) - Development setup
- [docs/AWS_IAM_SETUP.md](docs/AWS_IAM_SETUP.md) - GitHub Actions setup
- [docs/ANSIBLE_NEXT_STEPS.md](docs/ANSIBLE_NEXT_STEPS.md) - Ansible configuration
