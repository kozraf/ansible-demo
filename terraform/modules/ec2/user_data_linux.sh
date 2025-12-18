#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install SSM Agent
wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
dpkg -i amazon-ssm-agent.deb
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

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
