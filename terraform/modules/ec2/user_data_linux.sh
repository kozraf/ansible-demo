#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install SSM Agent (Ubuntu 24.04 comes with snap SSM agent pre-installed)
# Check if SSM agent is already installed via snap
if snap list amazon-ssm-agent >/dev/null 2>&1; then
    echo "SSM agent already installed via snap"
    # Ensure the service is enabled and running
    snap start amazon-ssm-agent || true
else
    # Try to install via dpkg, but don't fail if it already exists
    wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb || true
    dpkg -i amazon-ssm-agent.deb || true
    systemctl enable amazon-ssm-agent || true
    systemctl start amazon-ssm-agent || true
fi

# Verify SSM agent is running (check both snap and systemctl)
if snap list amazon-ssm-agent >/dev/null 2>&1; then
    snap services amazon-ssm-agent || echo "SSM agent snap service status check"
elif systemctl is-active --quiet amazon-ssm-agent; then
    echo "SSM agent running via systemctl"
else
    echo "SSM agent status check failed"
fi

# Install dependencies for Ansible management
apt-get install -y \
    python3-pip \
    python3 \
    openssh-server \
    openssh-client \
    curl \
    wget \
    git \
    sudo

# Ensure SSH is running
systemctl enable ssh
systemctl start ssh

# Create ansible user
useradd -m -s /bin/bash ansible || true
echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/ansible
chmod 440 /etc/sudoers.d/ansible

# Setup SSH for ansible user
mkdir -p /home/ansible/.ssh
chmod 700 /home/ansible/.ssh
chown -R ansible:ansible /home/ansible

echo "Linux host setup complete"
