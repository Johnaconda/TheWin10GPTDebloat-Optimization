# Set PowerShell to stop on errors
$ErrorActionPreference = "Stop"

Write-Host "Reverting PC to balanced settings..." -ForegroundColor Yellow

# Restore Balanced Power Plan
Write-Host "Restoring Balanced power plan..." -ForegroundColor Cyan
$powerPlan = Get-CimInstance -Namespace root\cimv2\power -ClassName Win32_PowerPlan | Where-Object { $_.ElementName -eq "Balanced" }
if ($powerPlan) {
    powercfg -setactive $powerPlan.InstanceID
    Write-Host "Balanced power plan activated." -ForegroundColor Green
} else {
    Write-Host "Balanced power plan not found. Skipping..." -ForegroundColor Red
}

# Restore Prioritization of Applications
Write-Host "Restoring default foreground application prioritization..." -ForegroundColor Cyan
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 2

# Re-enable Disabled Services
Write-Host "Re-enabling previously disabled services..." -ForegroundColor Cyan
$services = @(
    "DiagTrack",                  # Connected User Experiences and Telemetry
    "WSearch",                   # Windows Search
    "Spooler",                   # Print Spooler
    "SysMain",                   # Superfetch
    "Fax",                       # Fax
    "dmwappushservice",          # Device Management Wireless Application Protocol (WAP) Push
    "MapsBroker",                # Downloaded Maps Manager
    "RemoteRegistry",            # Remote Registry
    "RemoteAccess",              # Routing and Remote Access
    "XblAuthManager",            # Xbox Live Auth Manager
    "XblGameSave",               # Xbox Live Game Save
    "XboxNetApiSvc",             # Xbox Networking Service
    "XboxGipSvc"                 # Xbox Game Input Protocol
)

foreach ($service in $services) {
    Write-Host "Re-enabling service: $service" -ForegroundColor Cyan
    Set-Service -Name $service -StartupType Manual -ErrorAction SilentlyContinue
    Start-Service -Name $service -ErrorAction SilentlyContinue
}

# Re-enable Background Apps
Write-Host "Re-enabling background apps..." -ForegroundColor Cyan
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 0

# Restore Visual Effects
Write-Host "Restoring visual effects..." -ForegroundColor Cyan
$regPath = "HKCU:\Control Panel\Desktop"
Set-ItemProperty -Path $regPath -Name "UserPreferencesMask" -Value ([byte[]](0x9E,0x3E,0x07,0x80,0x12,0x00,0x00,0x00)) -ErrorAction SilentlyContinue

# Restore CPU Throttling Settings
Write-Host "Restoring CPU throttling settings..." -ForegroundColor Cyan
PowerShell -Command "powercfg /setacvalueindex SCHEME_BALANCED SUB_PROCESSOR PROCTHROTTLEMAX 100"
PowerShell -Command "powercfg /setacvalueindex SCHEME_BALANCED SUB_PROCESSOR PROCTHROTTLEMIN 5"
PowerShell -Command "powercfg /setdcvalueindex SCHEME_BALANCED SUB_PROCESSOR PROCTHROTTLEMAX 100"
PowerShell -Command "powercfg /setdcvalueindex SCHEME_BALANCED SUB_PROCESSOR PROCTHROTTLEMIN 5"

# Revert NVIDIA GPU Performance Settings
Write-Host "Reverting NVIDIA GPU performance settings (if applied)..." -ForegroundColor Cyan
$NvidiaSettingsPath = "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global"
if (Test-Path $NvidiaSettingsPath) {
    Set-ItemProperty -Path $NvidiaSettingsPath -Name "PowerMizerEnable" -Value 1
    Set-ItemProperty -Path $NvidiaSettingsPath -Name "PerfLevelSrc" -Value 0x3333
    Write-Host "NVIDIA GPU performance settings reverted." -ForegroundColor Green
} else {
    Write-Host "NVIDIA settings not found. Skipping GPU optimization..." -ForegroundColor Red
}

# Remove Performance Firewall Rules
Write-Host "Removing gaming optimization firewall rules..." -ForegroundColor Cyan
Remove-NetFirewallRule -DisplayName "Gaming Performance Block" -ErrorAction SilentlyContinue

Write-Host "PC settings have been reverted to a balanced state!" -ForegroundColor Green
