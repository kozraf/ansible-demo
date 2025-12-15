<powershell>
# Enable WinRM for Ansible
Write-Host "Enabling WinRM..."
Enable-PSRemoting -Force

# Configure WinRM for basic auth
Write-Host "Configuring WinRM Basic Authentication..."
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true -Force
Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true -Force

# Increase WinRM memory quota for large playbooks
Set-Item WSMan:\localhost\Shell\MaxMemoryPerShellMB -Value 1024 -Force

# Create ansible user
Write-Host "Creating ansible user..."
$Password = ConvertTo-SecureString "AnsibleUser@123!" -AsPlainText -Force
New-LocalUser -Name "ansible" -Password $Password -FullName "Ansible User" -Description "Ansible Management User" -PasswordNeverExpires -ErrorAction SilentlyContinue

# Add ansible user to Administrators group
Add-LocalGroupMember -Group "Administrators" -Member "ansible" -ErrorAction SilentlyContinue

# Install Python 3.11 via Chocolatey
Write-Host "Installing Chocolatey..."
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

Write-Host "Installing Python 3.11..."
choco install python311 -y
$env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","User")

# Install pywinrm module
Write-Host "Installing pywinrm..."
pip install pywinrm

# Create directory for Ansible
New-Item -ItemType Directory -Path "C:\ansible" -Force | Out-Null
New-Item -ItemType Directory -Path "C:\ansible\inventory" -Force | Out-Null

# Restart WinRM service
Write-Host "Restarting WinRM service..."
Restart-Service WinRM -Force

Write-Host "Windows host setup complete!"
</powershell>
