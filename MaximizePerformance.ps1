# Set PowerShell to stop on errors
$ErrorActionPreference = "Stop"

Write-Host "Maximizing PC performance..." -ForegroundColor Yellow

# Enable High-Performance Power Plan
Write-Host "Setting High-Performance power plan..." -ForegroundColor Cyan
$powerPlan = Get-CimInstance -Namespace root\cimv2\power -ClassName Win32_PowerPlan | Where-Object { $_.ElementName -eq "High performance" }
if ($powerPlan) {
    powercfg -setactive $powerPlan.InstanceID
    Write-Host "High-Performance power plan activated." -ForegroundColor Green
} else {
    Write-Host "High-Performance power plan not found. Creating a new one..." -ForegroundColor Red
    powercfg -duplicatescheme SCHEME_MIN # Duplicates High Performance plan
    powercfg -setactive SCHEME_MIN
    Write-Host "High-Performance power plan created and activated." -ForegroundColor Green
}

# Prioritize Foreground Applications
Write-Host "Prioritizing foreground applications..." -ForegroundColor Cyan
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 26

# Disable Unnecessary Services
Write-Host "Disabling unnecessary services..." -ForegroundColor Cyan
$services = @(
    "DiagTrack",                  # Connected User Experiences and Telemetry
    "WSearch",                   # Windows Search
    "Spooler",                   # Print Spooler
    "SysMain",                   # Superfetch
    "Fax",                       # Fax
    "dmwappushservice",          # Device Management Wireless Application Protocol (WAP) Push
    "MapsBroker",                # Downloaded Maps Manager
    "RetailDemo",                # Retail Demo Service
    "RemoteRegistry",            # Remote Registry
    "RemoteAccess",              # Routing and Remote Access
    "XblAuthManager",            # Xbox Live Auth Manager
    "XblGameSave",               # Xbox Live Game Save
    "XboxNetApiSvc",             # Xbox Networking Service
    "XboxGipSvc"                 # Xbox Game Input Protocol
)

foreach ($service in $services) {
    Write-Host "Disabling service: $service" -ForegroundColor Cyan
    Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
    Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
}

# Disable Background Apps
Write-Host "Disabling background apps..." -ForegroundColor Cyan
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1

# Disable Visual Effects for Maximum Performance
Write-Host "Disabling visual effects for maximum performance..." -ForegroundColor Cyan
$regPath = "HKCU:\Control Panel\Desktop"
Set-ItemProperty -Path $regPath -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x12,0x00,0x00,0x00))

# Enable Full CPU Performance
Write-Host "Enabling full CPU performance..." -ForegroundColor Cyan
PowerShell -Command "powercfg /setacvalueindex SCHEME_MIN SUB_PROCESSOR PROCTHROTTLEMAX 100"
PowerShell -Command "powercfg /setacvalueindex SCHEME_MIN SUB_PROCESSOR PROCTHROTTLEMIN 100"
PowerShell -Command "powercfg /setacvalueindex SCHEME_MIN SUB_PROCESSOR IDLEMINIMUM 0"
PowerShell -Command "powercfg /setdcvalueindex SCHEME_MIN SUB_PROCESSOR PROCTHROTTLEMAX 100"
PowerShell -Command "powercfg /setdcvalueindex SCHEME_MIN SUB_PROCESSOR PROCTHROTTLEMIN 100"
PowerShell -Command "powercfg /setdcvalueindex SCHEME_MIN SUB_PROCESSOR IDLEMINIMUM 0"

# Ensure GPU is Running at Full Power
Write-Host "Enabling full GPU performance (NVIDIA users)..." -ForegroundColor Cyan
$NvidiaSettingsPath = "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global"
if (Test-Path $NvidiaSettingsPath) {
    Set-ItemProperty -Path $NvidiaSettingsPath -Name "PowerMizerEnable" -Value 0
    Set-ItemProperty -Path $NvidiaSettingsPath -Name "PerfLevelSrc" -Value 0x2222
    Write-Host "Full NVIDIA GPU performance enabled." -ForegroundColor Green
} else {
    Write-Host "NVIDIA settings not found. Skipping GPU optimization..." -ForegroundColor Red
}

# Block Unnecessary Inbound Traffic
Write-Host "Blocking unnecessary inbound traffic..." -ForegroundColor Cyan
New-NetFirewallRule -DisplayName "Gaming Performance Block" -Direction Inbound -Action Block -Protocol TCP -LocalPort 135,139,445,5985,5986 -ErrorAction SilentlyContinue

# Clear Temporary Files
Write-Host "Clearing temporary files..." -ForegroundColor Cyan
Remove-Item -Path "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Temporary files cleared." -ForegroundColor Green

Write-Host "Your PC is now configured for maximum performance!" -ForegroundColor Green
Write-Host "Bot you need to restart your pc to take effect" -ForegroundColor Yellow
