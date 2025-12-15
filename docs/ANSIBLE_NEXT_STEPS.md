# Ansible Configuration - Next Steps

Once your infrastructure is deployed via Terraform/Terragrunt, follow this guide to configure Ansible for managing your hosts.

## Overview

After the infrastructure deployment, you'll have:
- **Control Node**: Ubuntu 24.04 with Ansible already installed
- **Linux Host**: Ubuntu 24.04 ready for Ansible management
- **Windows Host**: Windows Server 2022 with WinRM enabled

## Step 1: Gather Instance Information

Get the public and private IPs of your instances:

```bash
cd terragrunt/dev
terragrunt output -json > outputs.json
```

From the outputs, note:
- `control_node_public_ip` - SSH into the control node
- `host1_linux_private_ip` - Target for Ansible on Linux
- `host2_windows_private_ip` - Target for Ansible on Windows

Or view directly:

```bash
terragrunt output control_node_public_ip
terragrunt output host1_linux_private_ip
terragrunt output host2_windows_private_ip
```

## Step 2: Connect to Control Node

SSH into the Ansible control node:

```bash
ssh -i /path/to/your/keypair.pem ubuntu@<control-node-public-ip>
```

Once connected, switch to the ansible user:

```bash
sudo su - ansible
```

## Step 3: Copy SSH Keys for Linux Host

### Option A: Automatic SSH Key Sharing (Recommended)

If you have the private key on the control node:

```bash
# As root or ubuntu user, copy the key
sudo cp /home/ubuntu/.ssh/authorized_keys /home/ansible/.ssh/authorized_keys
sudo chown ansible:ansible /home/ansible/.ssh/authorized_keys
```

### Option B: Manual Key Addition

1. Generate a new SSH key on the control node:

```bash
# As ansible user
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

2. Copy the public key to the Linux host:

```bash
# Get the public key
cat ~/.ssh/id_rsa.pub

# SSH to host1-linux and add the key
ssh -i /path/to/keypair.pem ubuntu@<host1-linux-public-ip>
echo "{{ ansible_public_key }}" >> ~/.ssh/authorized_keys
```

## Step 4: Configure Ansible Inventory

Edit the Ansible inventory file on the control node:

```bash
# As ansible user on control node
vi ~/inventory/hosts
```

Add the following configuration:

```ini
[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_rsa

[control]
localhost ansible_connection=local

[linux]
host1-linux ansible_host=10.0.1.x
# Replace 10.0.1.x with the actual private IP

[windows]
host2-windows ansible_host=10.0.1.y ansible_user=ansible ansible_password='AnsibleUser@123!' ansible_port=5985 ansible_connection=winrm ansible_winrm_transport=basic ansible_winrm_operation_timeout_sec=60 ansible_winrm_read_timeout_sec=60
# Replace 10.0.1.y with the actual private IP
```

Test the inventory:

```bash
ansible-inventory --inventory ~/inventory/hosts --list
```

## Step 5: Verify Connectivity

### Test Linux Host Connectivity

```bash
ansible -i ~/inventory/hosts host1-linux -m ping
```

Expected output:
```
host1-linux | SUCCESS => {
    "ansible.builtin.ping": "pong"
}
```

### Test Windows Host Connectivity

```bash
ansible -i ~/inventory/hosts host2-windows -m win_ping
```

Expected output:
```
host2-windows | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

### Test All Hosts

```bash
ansible -i ~/inventory/hosts all -m ping
```

## Step 6: Create Your First Playbook

Create a directory for playbooks:

```bash
mkdir -p ~/playbooks
cd ~/playbooks
```

Create a simple playbook for Linux:

```bash
cat > linux_update.yml << 'EOF'
---
- name: Update Linux hosts
  hosts: linux
  become: yes
  
  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        cache_valid_time: 3600
    
    - name: Install packages
      apt:
        name:
          - curl
          - wget
          - git
          - vim
        state: present
    
    - name: Show system info
      debug:
        msg: "{{ ansible_facts['ansible_os_family'] }}"
EOF
```

Create a playbook for Windows:

```bash
cat > windows_check.yml << 'EOF'
---
- name: Check Windows hosts
  hosts: windows
  
  tasks:
    - name: Get Windows version
      win_command: powershell -Command [System.Environment]::OSVersion
      register: win_version
    
    - name: Display Windows version
      debug:
        msg: "{{ win_version.stdout }}"
    
    - name: Install Chocolatey packages
      win_chocolatey:
        name: notepadplusplus
        state: present
EOF
```

## Step 7: Run Your First Playbooks

### Run Linux Playbook

```bash
ansible-playbook -i ~/inventory/hosts ~/playbooks/linux_update.yml
```

### Run Windows Playbook

```bash
ansible-playbook -i ~/inventory/hosts ~/playbooks/windows_check.yml
```

### Run All Playbooks

```bash
ansible-playbook -i ~/inventory/hosts ~/playbooks/*.yml
```

## Common Ansible Commands

### Ad-hoc Commands

```bash
# Execute command on Linux hosts
ansible -i ~/inventory/hosts linux -m command -a "uname -a"

# Execute command on Windows hosts
ansible -i ~/inventory/hosts windows -m win_shell -a "Get-ComputerInfo"

# Copy file to Linux host
ansible -i ~/inventory/hosts linux -m copy -a "src=/tmp/file.txt dest=/tmp/"

# Create user on Windows
ansible -i ~/inventory/hosts windows -m win_user -a "name=testuser password=Test@123"
```

### List Hosts

```bash
# List all hosts
ansible -i ~/inventory/hosts all --list-hosts

# List specific group
ansible -i ~/inventory/hosts linux --list-hosts
```

### Gather Facts

```bash
# Gather facts from all hosts
ansible -i ~/inventory/hosts all -m setup

# Gather facts from Linux only
ansible -i ~/inventory/hosts linux -m setup | grep ansible_distribution
```

## Troubleshooting

### SSH Connection Issues on Linux

```bash
# Test SSH manually
ssh -i ~/.ssh/id_rsa ubuntu@10.0.1.x

# Check SSH config
ansible -i ~/inventory/hosts linux -vvv -m ping

# Common issues:
# - Wrong IP address
# - Wrong SSH key
# - Security group not allowing SSH
```

### WinRM Connection Issues on Windows

```bash
# Test WinRM connectivity
ansible -i ~/inventory/hosts windows -m win_ping -vvv

# Common issues:
# - Wrong password (default: AnsibleUser@123!)
# - WinRM not enabled
# - Network issues
# - Windows host still initializing (wait 10-15 min after creation)
```

### Python Not Found

Install Python on managed hosts:

```bash
# For Linux
ansible -i ~/inventory/hosts linux -m raw -a "apt-get update && apt-get install -y python3"

# For Windows (usually auto-installed, but if needed)
ansible -i ~/inventory/hosts windows -m win_shell -a "powershell -Command 'if (-not (Test-Path C:\Python311)) { choco install python311 -y }'"
```

### Elevated Privileges

For tasks requiring sudo on Linux:

```yaml
- name: Task requiring sudo
  hosts: linux
  become: yes  # Use sudo
  become_user: root  # Optional, default is root
  
  tasks:
    - name: Update system
      apt:
        update_cache: yes
```

## Directory Structure on Control Node

```
/home/ansible/
├── inventory/
│   └── hosts              # Inventory file
├── playbooks/
│   ├── linux_update.yml
│   └── windows_check.yml
└── roles/                 # For complex playbooks (optional)
    ├── common/
    ├── webserver/
    └── database/
```

## Best Practices

1. **Organize Playbooks**: Group related tasks in separate files or use roles
2. **Use Variables**: Define variables in `group_vars/` or `host_vars/` directories
3. **Idempotency**: Ensure tasks are idempotent (safe to run multiple times)
4. **Error Handling**: Use `failed_when`, `changed_when`, `ignore_errors` appropriately
5. **Documentation**: Add comments and descriptions to your playbooks
6. **Testing**: Test playbooks on a single host before running on all hosts

## Example: Structured Playbook Layout

```
~/playbooks/
├── group_vars/
│   ├── linux.yml          # Variables for linux group
│   └── windows.yml        # Variables for windows group
├── roles/
│   └── common/
│       ├── tasks/
│       │   └── main.yml
│       └── templates/
├── site.yml               # Main playbook
└── linux_only.yml
```

## Next Steps

1. Create more complex playbooks for your use case
2. Set up roles for reusable configurations
3. Use variables and templates for flexibility
4. Implement error handling and retries
5. Consider using Ansible Tower/AWX for enterprise features
6. Integrate with CI/CD pipelines

## Resources

- [Ansible Official Documentation](https://docs.ansible.com/)
- [Ansible Galaxy - Community Roles](https://galaxy.ansible.com/)
- [Ansible Windows Guide](https://docs.ansible.com/ansible/latest/os_guide/windows_setup.html)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_and_tricks.html)

## Resetting/Rebuilding Infrastructure

If you need to start over:

```bash
# From your local machine
cd terragrunt/dev
terragrunt destroy
terragrunt apply
```

Then repeat steps 1-5 to reconfigure Ansible.
