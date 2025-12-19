#!/bin/bash
set -euo pipefail

# Redirect all output to a logfile and keep stdout/stderr visible
exec > >(tee -a /var/log/user-data.log) 2>&1

log() { printf "%s %s\n" "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*"; }
step_complete() { log "STEP_COMPLETE: $1"; echo "STEP_COMPLETE: $1" >> /var/log/user-data-steps.log; }

trap 'log "ERROR: user-data aborted at line ${LINENO}"; echo "ERROR at line ${LINENO}" >> /var/log/user-data-steps.log; exit 1' ERR

log "Starting user-data"

step="update-packages"
log "STEP: ${step} - updating apt and upgrading packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y
step_complete "${step}"

step="ssm-agent"
log "STEP: ${step} - SSM agent handling"
# Ubuntu 24.04 may ship amazon-ssm-agent via snap. Prefer snap-managed instance.
if snap list amazon-ssm-agent >/dev/null 2>&1; then
    log "SSM agent present via snap"
    snap start amazon-ssm-agent || log "snap start returned non-zero"
else
    log "SSM agent not in snap; attempting dpkg install (non-fatal)"
    wget -q https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb || log "wget failed"
    dpkg -i amazon-ssm-agent.deb || log "dpkg install returned non-zero"
    systemctl enable amazon-ssm-agent || log "systemctl enable failed"
    systemctl start amazon-ssm-agent || log "systemctl start failed"
fi

# Verify SSM agent in either location
if snap list amazon-ssm-agent >/dev/null 2>&1; then
    snap services amazon-ssm-agent || log "snap services check failed"
elif systemctl is-active --quiet amazon-ssm-agent; then
    log "SSM agent running via systemctl"
else
    log "SSM agent not detected after install attempts"
fi
step_complete "${step}"

step="install-packages"
log "STEP: ${step} - installing base packages"
apt-get install -y --no-install-recommends \
    python3-venv python3-dev build-essential \
    git curl wget openssh-server openssh-client jq vim nano ca-certificates unzip
step_complete "${step}"

step="install-awscli"
log "STEP: ${step} - installing AWS CLI v2"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip
step_complete "${step}"

step="create-ansible-venv"
log "STEP: ${step} - creating isolated Ansible venv at /opt/ansible-venv"
python3 -m venv /opt/ansible-venv
chmod 755 /opt/ansible-venv
/opt/ansible-venv/bin/python -m pip install --upgrade pip setuptools wheel
/opt/ansible-venv/bin/pip install --no-cache-dir ansible ansible-core || log "pip install into venv failed"
ln -s /opt/ansible-venv/bin/ansible /usr/local/bin/ansible || true
ln -s /opt/ansible-venv/bin/ansible-playbook /usr/local/bin/ansible-playbook || true
step_complete "${step}"

step="create-ansible-user"
log "STEP: ${step} - creating ansible user and directories"
useradd -m -s /bin/bash ansible || log "useradd returned non-zero"
echo "ansible ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ansible
chmod 440 /etc/sudoers.d/ansible

# Retrieve ansible user password from Secrets Manager
ansible_password=$(aws secretsmanager get-secret-value --secret-id ansible-poc-ansible-password --query SecretString --output text) || log "Failed to retrieve ansible password from Secrets Manager"
echo "ansible:$ansible_password" | chpasswd || log "chpasswd failed"

sudo -u ansible mkdir -p /home/ansible/.ssh /home/ansible/playbooks /home/ansible/inventory
sudo -u ansible ssh-keygen -t rsa -b 4096 -f /home/ansible/.ssh/id_rsa -N "" || log "ssh-keygen returned non-zero"
chmod 700 /home/ansible/.ssh
chown -R ansible:ansible /home/ansible
echo 'export PATH=/opt/ansible-venv/bin:$PATH' > /home/ansible/.profile
step_complete "${step}"

step="create-inventory"
log "STEP: ${step} - writing basic inventory"
cat > /home/ansible/inventory/hosts << 'EOF'
[control]
localhost ansible_connection=local

[linux]
# host1-linux will be added later

[windows]
# host2-win will be added later
EOF
chown ansible:ansible /home/ansible/inventory/hosts
step_complete "${step}"

step="verify-ansible"
log "STEP: ${step} - validating ansible binary and version"
/opt/ansible-venv/bin/ansible --version || log "ansible --version failed"
step_complete "${step}"

log "User-data finished successfully"
step_complete "all-complete"
 
