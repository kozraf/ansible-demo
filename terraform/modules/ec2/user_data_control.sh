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

# Install Ansible and dependencies
apt-get install -y \
    python3-pip \
    python3-venv \
    python3-dev \
    git \
    curl \
    wget \
    openssh-server \
    openssh-client \
    jq \
    vim \
    nano

# Install Ansible via pip
pip3 install --upgrade pip
pip3 install ansible ansible-core

# Create ansible user
useradd -m -s /bin/bash ansible || true
echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/ansible

# Generate SSH key for ansible user
sudo -u ansible ssh-keygen -t rsa -b 4096 -f /home/ansible/.ssh/id_rsa -N "" || true
sudo -u ansible chmod 700 /home/ansible/.ssh

# Create ansible directories
mkdir -p /home/ansible/playbooks
mkdir -p /home/ansible/inventory
chown -R ansible:ansible /home/ansible

# Create a basic inventory file
cat > /home/ansible/inventory/hosts << 'EOF'
[control]
localhost ansible_connection=local

[linux]
# host1-linux will be added later

[windows]
# host2-win will be added later
EOF

chown ansible:ansible /home/ansible/inventory/hosts

echo "Ansible control node setup complete"
