# Disable Windows Remote Management (WinRM)
Write-Host "Disabling Windows Remote Management (WinRM)..." -ForegroundColor Yellow
Stop-Service -Name WinRM -Force
Set-Service -Name WinRM -StartupType Disabled

# Disable Remote Desktop Protocol (RDP)
Write-Host "Disabling Remote Desktop (RDP)..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 1

# Disable Remote Assistance
Write-Host "Disabling Remote Assistance..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Value 0

# Disable Remote Registry Service
Write-Host "Disabling Remote Registry Service..." -ForegroundColor Yellow
Stop-Service -Name RemoteRegistry -Force
Set-Service -Name RemoteRegistry -StartupType Disabled

# Disable Remote Access Connection Manager
Write-Host "Disabling Remote Access Connection Manager..." -ForegroundColor Yellow
Stop-Service -Name RasMan -Force
Set-Service -Name RasMan -StartupType Disabled

# Disable Routing and Remote Access
Write-Host "Disabling Routing and Remote Access..." -ForegroundColor Yellow
Stop-Service -Name RemoteAccess -Force
Set-Service -Name RemoteAccess -StartupType Disabled

# Disable Windows Remote Desktop Services UserMode Port Redirector
Write-Host "Disabling Remote Desktop Services UserMode Port Redirector..." -ForegroundColor Yellow
Stop-Service -Name UmRdpService -Force
Set-Service -Name UmRdpService -StartupType Disabled

# Disable SSH Server (if installed)
Write-Host "Disabling SSH Server (if installed)..." -ForegroundColor Yellow
if (Get-Service -Name sshd -ErrorAction SilentlyContinue) {
    Stop-Service -Name sshd -Force
    Set-Service -Name sshd -StartupType Disabled
} else {
    Write-Host "SSH Server is not installed." -ForegroundColor Green
}

# Disable Telnet (if installed)
Write-Host "Disabling Telnet (if installed)..." -ForegroundColor Yellow
if (Get-WindowsOptionalFeature -FeatureName TelnetClient -Online | Select-Object -ExpandProperty State -ErrorAction SilentlyContinue) {
    Disable-WindowsOptionalFeature -FeatureName TelnetClient -Online -NoRestart
    Write-Host "Telnet feature has been disabled." -ForegroundColor Green
} else {
    Write-Host "Telnet is not installed." -ForegroundColor Green
}

# Disable Windows Firewall Remote Management Rules
Write-Host "Disabling Windows Firewall Remote Management Rules..." -ForegroundColor Yellow
New-NetFirewallRule -DisplayName "Disable Remote Management" -Direction Inbound -Action Block -Protocol TCP -LocalPort 5985,5986

Write-Host "All remote-related features have been disabled." -ForegroundColor Green
