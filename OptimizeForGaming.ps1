# Set PowerShell to stop on errors
$ErrorActionPreference = "Stop"

# Disable Unnecessary Services
Write-Host "Disabling unnecessary services..." -ForegroundColor Yellow
$services = @(
    "DiagTrack",                  # Connected User Experiences and Telemetry
    "WSearch",                   # Windows Search
    "Spooler",                   # Print Spooler
    "RemoteRegistry",            # Remote Registry
    "SysMain",                   # Superfetch
    "Fax",                       # Fax
    "RetailDemo",                # Retail Demo Service
    "dmwappushservice",          # Device Management Wireless Application Protocol (WAP) Push
    "MapsBroker",                # Downloaded Maps Manager
    "Downloaded Maps Manager"    # Redundant Maps Service
)

foreach ($service in $services) {
    Write-Host "Disabling service: $service" -ForegroundColor Cyan
    Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
    Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
}

# Disable Background Apps
Write-Host "Disabling background apps..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1

# Disable Unnecessary Startup Programs
Write-Host "Disabling unnecessary startup programs..." -ForegroundColor Yellow
$startupPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
)

foreach ($path in $startupPaths) {
    Get-ItemProperty -Path $path | ForEach-Object {
        Write-Host "Disabling startup program: $($_.PSChildName)" -ForegroundColor Cyan
        Remove-ItemProperty -Path $path -Name $_.PSChildName -ErrorAction SilentlyContinue
    }
}

# Disable Xbox Services (if not needed)
Write-Host "Disabling Xbox services..." -ForegroundColor Yellow
$XboxServices = @(
    "XblAuthManager",
    "XblGameSave",
    "XboxNetApiSvc",
    "XboxGipSvc"
)

foreach ($service in $XboxServices) {
    Write-Host "Disabling service: $service" -ForegroundColor Cyan
    Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
    Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
}

# Disable Remote Features
Write-Host "Disabling remote connection features..." -ForegroundColor Yellow
Stop-Service -Name "WinRM" -Force -ErrorAction SilentlyContinue
Set-Service -Name "WinRM" -StartupType Disabled -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 1
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Value 0

# Enable High-Performance Power Plan
Write-Host "Setting High-Performance Power Plan..." -ForegroundColor Yellow
$powerPlan = Get-CimInstance -Namespace root\cimv2\power -ClassName Win32_PowerPlan | Where-Object { $_.ElementName -eq "High performance" }
if ($powerPlan) {
    powercfg -setactive $powerPlan.InstanceID
} else {
    Write-Host "High-performance power plan not found. Creating one..." -ForegroundColor Red
}

# Disable Visual Effects for Performance
Write-Host "Disabling visual effects..." -ForegroundColor Yellow
$regPath = "HKCU:\Control Panel\Desktop"
Set-ItemProperty -Path $regPath -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x12,0x00,0x00,0x00)) -ErrorAction SilentlyContinue

# Clean Temporary Files
Write-Host "Cleaning temporary files..." -ForegroundColor Yellow
Remove-Item -Path "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Temporary files cleaned." -ForegroundColor Green

# Block unnecessary inbound traffic for gaming
Write-Host "Blocking unnecessary inbound firewall traffic..." -ForegroundColor Yellow
New-NetFirewallRule -DisplayName "Gaming Optimization Block" -Direction Inbound -Action Block -Protocol TCP -LocalPort 135,139,445,5985,5986 -ErrorAction SilentlyContinue

Write-Host "Windows is now optimized for gaming!" -ForegroundColor Green
