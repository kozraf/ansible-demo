# Local Development Guide

This guide helps you set up your local environment for developing and testing the Ansible PoC infrastructure.

## Prerequisites

- **Terraform**: [Download v1.6.0+](https://www.terraform.io/downloads)
- **Terragrunt**: [Download v0.54.0+](https://terragrunt.gruntwork.io/docs/getting-started/install/)
- **AWS CLI**: [Download and configure](https://aws.amazon.com/cli/)
- **Git**: For version control
- **Text Editor/IDE**: VS Code, IntelliJ, etc.

## macOS/Linux Setup

### 1. Install Tools via Homebrew

```bash
# Install Terraform
brew install terraform

# Install Terragrunt
brew install terragrunt

# Install AWS CLI
brew install awscli
```

### 2. Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: us-east-1
# Default output format: json
```

### 3. Verify Installation

```bash
terraform version
terragrunt --version
aws sts get-caller-identity
```

## Windows Setup

### 1. Install Tools via Chocolatey

```powershell
# Run PowerShell as Administrator

# Install Terraform
choco install terraform -y

# Install Terragrunt
choco install terragrunt -y

# Install AWS CLI
choco install awscli -y
```

### 2. Configure AWS Credentials

```powershell
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: us-east-1
# Default output format: json
```

### 3. Verify Installation

```powershell
terraform version
terragrunt --version
aws sts get-caller-identity
```

## Project Structure Navigation

```
terraform/                      # Terraform code
├── backend-infrastructure/     # S3 + DynamoDB for state
├── modules/
│   └── ec2/                    # EC2 instances module
└── main.tf                     # VPC, subnets, security groups

terragrunt/                     # Terragrunt configurations
├── backend-infrastructure/     # Backend infrastructure config
├── dev/                        # Development environment config
└── terragrunt.hcl             # Root configuration
```

## Common Development Tasks

### Initialize Backend Infrastructure

First time only - creates S3 bucket and DynamoDB table:

```bash
cd terragrunt/backend-infrastructure
terragrunt init
terragrunt plan
terragrunt apply
```

### Initialize Development Environment

```bash
cd terragrunt/dev
terragrunt init
```

### Plan Infrastructure Changes

```bash
cd terragrunt/dev
terragrunt plan
```

Save the plan to a file:

```bash
cd terragrunt/dev
terragrunt plan -out=tfplan
```

### Apply Infrastructure Changes

```bash
cd terragrunt/dev
terragrunt apply
```

Or with a saved plan:

```bash
cd terragrunt/dev
terragrunt apply tfplan
```

### View Current Outputs

```bash
cd terragrunt/dev
terragrunt output
```

View specific output as JSON:

```bash
cd terragrunt/dev
terragrunt output -json | jq '.control_node_public_ip.value'
```

### Destroy Resources

```bash
# Destroy dev infrastructure
cd terragrunt/dev
terragrunt destroy

# Destroy backend infrastructure (if needed)
cd terragrunt/backend-infrastructure
terragrunt destroy
```

## Validating Changes

### Format Check

```bash
# Check formatting
terraform fmt -check -recursive terraform/

# Auto-format
terraform fmt -recursive terraform/
```

### Validate Syntax

```bash
cd terragrunt/dev
terragrunt validate
```

### Linting (Optional)

Install TFLint:

```bash
brew install tflint  # macOS
choco install tflint # Windows
```

Run linting:

```bash
tflint --init
cd terragrunt/dev
tflint
```

## Debugging

### Enable Debug Logging

```bash
# Terraform debug
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log
terragrunt plan

# Unset after debugging
unset TF_LOG
unset TF_LOG_PATH
```

### View Terragrunt Configuration

```bash
cd terragrunt/dev
terragrunt config
```

### Check What Will Be Generated

```bash
cd terragrunt/dev
terragrunt render-json
```

## Making Changes

### Modifying Variables

1. Edit `terragrunt/dev/terragrunt.hcl` to change input variables
2. Run `terragrunt plan` to review changes
3. Run `terragrunt apply` to apply changes

Example: Change instance type from t2.micro to t2.small

```hcl
# terragrunt/dev/terragrunt.hcl
inputs = {
  instance_type = "t2.small"  # Changed from t2.micro
}
```

### Adding New Resources

1. Create a new `.tf` file in `terraform/`
2. Define resources using Terraform syntax
3. Add outputs if needed to `terraform/outputs.tf`
4. Run `terragrunt plan` to validate
5. Run `terragrunt apply` to create resources

### Modifying Module Code

1. Edit files in `terraform/modules/ec2/`
2. Run `terragrunt plan` to see the impact
3. The changes will be reflected in the next apply

## Working with State

### List Resources in State

```bash
cd terragrunt/dev
terragrunt state list
```

### Show Specific Resource

```bash
cd terragrunt/dev
terragrunt state show aws_instance.control_node
```

### View State Lock

```bash
aws dynamodb scan --table-name ansible-poc-tf-locks --region us-east-1
```

### Remove Lock (if stuck)

```bash
aws dynamodb delete-item \
  --table-name ansible-poc-tf-locks \
  --key '{"LockID":{"S":"terraform/terraform.tfstate"}}' \
  --region us-east-1
```

## Tips and Best Practices

1. **Always Plan First**: Run `terragrunt plan` before `terragrunt apply`
2. **Use .tfvars Files**: For sensitive values, create `terraform.tfvars` (ignored by git)
3. **Review Changes**: Carefully review plan output before applying
4. **Test Incrementally**: Make small changes and test thoroughly
5. **Use Workspaces**: For multiple environments, consider Terraform workspaces
6. **Document Changes**: Commit meaningful commit messages
7. **Keep State Secure**: Never commit `.tfstate` files or credentials

## Troubleshooting

### "No configuration files found"

Ensure you're in the correct directory:
```bash
pwd  # Verify you're in terragrunt/backend-infrastructure or terragrunt/dev
```

### "Error acquiring the state lock"

State is locked. Check who has it:
```bash
aws dynamodb scan --table-name ansible-poc-tf-locks --region us-east-1
```

### "Access Denied" errors

Verify AWS credentials are configured:
```bash
aws sts get-caller-identity
```

### "Unable to locate credentials"

Configure AWS credentials:
```bash
aws configure
```

### Slow `terragrunt apply`

Windows instances take 10-15 minutes to fully initialize. This is normal.

## Next Steps

1. Complete the [AWS IAM Setup](AWS_IAM_SETUP.md) for GitHub Actions
2. Push changes to GitHub to trigger CI/CD pipelines
3. Monitor GitHub Actions workflow runs
4. Once infrastructure is deployed, follow the [Ansible Configuration Guide](ANSIBLE_NEXT_STEPS.md)
