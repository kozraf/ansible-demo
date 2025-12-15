# AWS IAM Role Setup for GitHub Actions

This document provides step-by-step instructions for setting up AWS IAM authentication with GitHub Actions using OIDC (OpenID Connect).

## Why OIDC?

OIDC allows GitHub Actions to authenticate to AWS without storing long-lived AWS access keys in GitHub secrets. This is more secure and follows AWS best practices.

## Prerequisites

- AWS Account with IAM permissions
- GitHub repository with admin access
- AWS CLI installed locally (optional but recommended)

## Step 1: Create OIDC Identity Provider

### Option A: Using AWS CLI

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aca1 \
  --region us-east-1
```

### Option B: Using AWS Console

1. Go to IAM → Identity Providers
2. Click "Create Provider"
3. Select "OpenID Connect"
4. Provider URL: `https://token.actions.githubusercontent.com`
5. Audience: `sts.amazonaws.com`
6. Thumbprint: `6938fd4d98bab03faadb97b34396831e3780aca1`

## Step 2: Create IAM Role

### Using AWS Console

1. Go to IAM → Roles → Create Role
2. Select "Web Identity" as the trusted entity type
3. Identity provider: `token.actions.githubusercontent.com`
4. Audience: `sts.amazonaws.com`
5. Subject: `repo:<github-org>/<repo-name>:*` (e.g., `repo:myorg/ansible-demo:*`)
6. Click Next and attach the policy (see below)

### Using AWS CLI

First, save this as `trust-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT-ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR-ORG/YOUR-REPO:*"
        }
      }
    }
  ]
}
```

Replace `ACCOUNT-ID`, `YOUR-ORG`, and `YOUR-REPO` with your actual values.

Then create the role:

```bash
aws iam create-role \
  --role-name GitHubActionsAnsiblePoCRole \
  --assume-role-policy-document file://trust-policy.json
```

## Step 3: Attach Permissions Policy

### Minimum Required Permissions

Save this as `permissions-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "vpc:*",
        "s3:*",
        "dynamodb:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateUser",
        "iam:GetUser",
        "iam:CreateAccessKey",
        "iam:ListAccessKeys"
      ],
      "Resource": "*"
    }
  ]
}
```

Attach the policy:

```bash
aws iam put-role-policy \
  --role-name GitHubActionsAnsiblePoCRole \
  --policy-name TerraformPolicy \
  --policy-document file://permissions-policy.json
```

Or via AWS Console:
1. Go to the role
2. Click "Add Inline Policy"
3. Paste the JSON above

## Step 4: Add Role ARN to GitHub Secrets

1. Get your role ARN (format: `arn:aws:iam::ACCOUNT-ID:role/GitHubActionsAnsiblePoCRole`)

2. Go to your GitHub repository:
   - Settings → Secrets and Variables → Actions → New Repository Secret

3. Create a new secret:
   - Name: `AWS_ROLE_TO_ASSUME`
   - Value: `arn:aws:iam::ACCOUNT-ID:role/GitHubActionsAnsiblePoCRole`

## Step 5: Verify Setup

Run the plan workflow:

1. Create a test branch: `git checkout -b test/setup`
2. Make a minor change to `terraform/variables.tf` (e.g., update a comment)
3. Create a pull request
4. The "Terraform Plan" workflow should trigger
5. Check the workflow logs to confirm AWS authentication succeeded

## Troubleshooting

### Error: "InvalidIdentityToken: Token uses invalid subject claim"

Make sure your GitHub repository reference in the trust policy is correct:
```
repo:YOUR-ORG/YOUR-REPO:*
```

### Error: "User: arn:aws:iam::... is not authorized"

The IAM role doesn't have the required permissions. Review and attach the permissions policy.

### Error: "Error making API call AssumeRoleWithWebIdentity"

Verify that:
1. The OIDC provider exists in IAM
2. The role trust policy has the correct principal
3. The role ARN in GitHub secrets is correct

## Advanced Configuration

### Limit by Branch

To only allow deployments from specific branches:

```json
"StringLike": {
  "token.actions.githubusercontent.com:sub": "repo:YOUR-ORG/YOUR-REPO:ref:refs/heads/main"
}
```

### Limit by Environment

To restrict deployments to specific GitHub environments:

```json
"StringLike": {
  "token.actions.githubusercontent.com:sub": "repo:YOUR-ORG/YOUR-REPO:environment:production"
}
```

## References

- [GitHub Actions: About security hardening with OpenID Connect](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [AWS: AssumeRoleWithWebIdentity](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRoleWithWebIdentity.html)
- [AWS: Creating OpenID Connect (OIDC) identity providers](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
