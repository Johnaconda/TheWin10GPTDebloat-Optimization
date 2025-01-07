# Set PowerShell to stop on errors
$ErrorActionPreference = "Stop"

Write-Host "Restoring remote connection features..." -ForegroundColor Yellow

# Enable Windows Remote Management (WinRM)
Write-Host "Enabling Windows Remote Management (WinRM)..." -ForegroundColor Cyan
Set-Service -Name "WinRM" -StartupType Manual
Start-Service -Name "WinRM" -ErrorAction SilentlyContinue

# Enable Remote Desktop (RDP)
Write-Host "Enabling Remote Desktop (RDP)..." -ForegroundColor Cyan
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0

# Enable Remote Assistance
Write-Host "Enabling Remote Assistance..." -ForegroundColor Cyan
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Value 1

# Enable Remote Registry Service
Write-Host "Enabling Remote Registry Service..." -ForegroundColor Cyan
Set-Service -Name "RemoteRegistry" -StartupType Manual
Start-Service -Name "RemoteRegistry" -ErrorAction SilentlyContinue

# Enable Routing and Remote Access
Write-Host "Enabling Routing and Remote Access..." -ForegroundColor Cyan
Set-Service -Name "RemoteAccess" -StartupType Manual
Start-Service -Name "RemoteAccess" -ErrorAction SilentlyContinue

# Enable Remote Desktop Services UserMode Port Redirector
Write-Host "Enabling Remote Desktop Services UserMode Port Redirector..." -ForegroundColor Cyan
Set-Service -Name "UmRdpService" -StartupType Manual
Start-Service -Name "UmRdpService" -ErrorAction SilentlyContinue

Write-Host "Remote connection features have been restored!" -ForegroundColor Green
