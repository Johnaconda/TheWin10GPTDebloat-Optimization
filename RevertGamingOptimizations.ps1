# Set PowerShell to stop on errors
$ErrorActionPreference = "Stop"

Write-Host "Restoring Windows settings for general use..." -ForegroundColor Yellow

# Enable Previously Disabled Services
Write-Host "Enabling previously disabled services..." -ForegroundColor Cyan
$services = @(
    "DiagTrack",                  # Connected User Experiences and Telemetry
    "WSearch",                   # Windows Search
    "Spooler",                   # Print Spooler
    "SysMain",                   # Superfetch
    "Fax",                       # Fax
    "RetailDemo",                # Retail Demo Service
    "dmwappushservice",          # Device Management Wireless Application Protocol (WAP) Push
    "MapsBroker",                # Downloaded Maps Manager
    "XblAuthManager",            # Xbox Live Auth Manager
    "XblGameSave",               # Xbox Live Game Save
    "XboxNetApiSvc",             # Xbox Networking Service
    "XboxGipSvc"                 # Xbox Game Input Protocol
)

foreach ($service in $services) {
    Write-Host "Enabling service: $service" -ForegroundColor Cyan
    Set-Service -Name $service -StartupType Manual -ErrorAction SilentlyContinue
    Start-Service -Name $service -ErrorAction SilentlyContinue
}

# Enable Background Apps
Write-Host "Enabling background apps..." -ForegroundColor Cyan
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 0

# Restore Visual Effects
Write-Host "Restoring visual effects..." -ForegroundColor Cyan
$regPath = "HKCU:\Control Panel\Desktop"
Set-ItemProperty -Path $regPath -Name "UserPreferencesMask" -Value ([byte[]](0x9E,0x3E,0x07,0x80,0x12,0x00,0x00,0x00)) -ErrorAction SilentlyContinue

# Remove Gaming Firewall Rules
Write-Host "Removing gaming optimization firewall rules..." -ForegroundColor Cyan
Remove-NetFirewallRule -DisplayName "Gaming Optimization Block" -ErrorAction SilentlyContinue

# Restore Power Plan to Balanced
Write-Host "Restoring Balanced power plan..." -ForegroundColor Cyan
$powerPlan = Get-CimInstance -Namespace root\cimv2\power -ClassName Win32_PowerPlan | Where-Object { $_.ElementName -eq "Balanced" }
if ($powerPlan) {
    powercfg -setactive $powerPlan.InstanceID
    Write-Host "Balanced power plan has been restored." -ForegroundColor Green
} else {
    Write-Host "Balanced power plan not found. Skipping..." -ForegroundColor Red
}

Write-Host "Windows settings for general use have been restored!" -ForegroundColor Green
