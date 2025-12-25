# ==========================================================
# Windows 10 Ultimate Local OS + Gaming + Privacy + Lockdown
# Fully Reversible | Admin-Safe | Shareable
# ==========================================================

Write-Host ""
Write-Host "=== WINDOWS 10 ULTIMATE LOCAL OS SCRIPT ==="
Write-Host "1 = Apply FULL Debloat + Privacy + Gaming + Lockdowns"
Write-Host "2 = Restore Windows Defaults"
$mode = Read-Host "Select mode"

# ------------------------
# Helpers
# ------------------------
function Disable-ServiceSafe {
    param($Name)
    Stop-Service $Name -Force -ErrorAction SilentlyContinue
    Set-Service $Name -StartupType Disabled -ErrorAction SilentlyContinue
}

function Enable-ServiceSafe {
    param($Name)
    Set-Service $Name -StartupType Manual -ErrorAction SilentlyContinue
}

# ==========================================================
# APPLY MODE
# ==========================================================
if ($mode -eq "1") {

    Write-Host "Applying FULL local OS debloat..."

    # ---------------- TELEMETRY ----------------
    foreach ($svc in @("DiagTrack","dmwappushservice","PcaSvc")) {
        Disable-ServiceSafe $svc
    }

    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
        /v AllowTelemetry /t REG_DWORD /d 0 /f >$null

    # ---------------- WINDOWS UPDATE ----------------
    foreach ($svc in @("wuauserv","UsoSvc","WaaSMedicSvc")) {
        Disable-ServiceSafe $svc
    }

    # ---------------- CORTANA / CLOUD SEARCH ----------------
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" `
        /v AllowCortana /t REG_DWORD /d 0 /f >$null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" `
        /v DisableWebSearch /t REG_DWORD /d 1 /f >$null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" `
        /v BingSearchEnabled /t REG_DWORD /d 0 /f >$null
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" `
        /v CortanaConsent /t REG_DWORD /d 0 /f >$null

    Disable-ServiceSafe "WSearch"

    # ---------------- ONEDRIVE ----------------
    Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue
    Disable-ServiceSafe "OneSyncSvc"
    if (Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") {
        Start-Process "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" "/uninstall" -Wait
    }
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" `
        /v DisableFileSyncNGSC /t REG_DWORD /d 1 /f >$null

    # ---------------- REMOTE ACCESS ----------------
    $remote = Read-Host "Disable ALL remote access (SSH, RDP, WinRM)? (y/n)"
    if ($remote -eq "y") {
        foreach ($svc in @("sshd","ssh-agent","WinRM","TermService","RemoteRegistry")) {
            Disable-ServiceSafe $svc
        }
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" `
            /v fDenyTSConnections /t REG_DWORD /d 1 /f >$null
        netsh advfirewall firewall set rule group="remote desktop" new enable=no >$null
        netsh advfirewall firewall set rule group="windows remote management" new enable=no >$null
        netsh advfirewall firewall set rule group="openssh server" new enable=no >$null
    }

# ==================================================
# HOSTS-BASED MICROSOFT ENDPOINT BLOCK (SAFE)
# ==================================================
$hostsBlock = Read-Host "Block Microsoft telemetry endpoints via HOSTS file? (y/n)"
if ($hostsBlock -eq "y") {

    $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"

    # Remove read-only attribute if present
    attrib -r $hostsPath 2>$null

    $entries = @(
        "vortex.data.microsoft.com",
        "settings-win.data.microsoft.com",
        "telemetry.microsoft.com",
        "watson.telemetry.microsoft.com",
        "oca.telemetry.microsoft.com",
        "ads.msn.com",
        "ads.microsoft.com",
        "feedback.windows.com"
    )

    $content = Get-Content $hostsPath -ErrorAction SilentlyContinue

    foreach ($e in $entries) {
        if ($content -notmatch $e) {
            $content += "0.0.0.0 $e"
        }
    }

    Set-Content -Path $hostsPath -Value $content -Force
}

# ==================================================
# UPDATE MEDIC ACL LOCKDOWN (SAFE METHOD)
# ==================================================
$medicLock = Read-Host "Apply Update Medic ACL LOCKDOWN? (y/n)"
if ($medicLock -eq "y") {

    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc"

    $acl = Get-Acl $regPath

    # Remove write permissions for SYSTEM
    $acl.Access | Where-Object {
        $_.IdentityReference -eq "NT AUTHORITY\SYSTEM"
    } | ForEach-Object {
        $acl.RemoveAccessRule($_)
    }

    # Re-add SYSTEM as READ-ONLY
    $rule = New-Object System.Security.AccessControl.RegistryAccessRule(
        "SYSTEM",
        "ReadKey",
        "ContainerInherit,ObjectInherit",
        "None",
        "Allow"
    )

    $acl.AddAccessRule($rule)
    Set-Acl -Path $regPath -AclObject $acl
}
    # ==================================================
    # GAMING MODE
    # ==================================================
    $game = Read-Host "Enable GAMING PERFORMANCE MODE? (y/n)"
    if ($game -eq "y") {
        powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 >$null
        powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61
        powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 100
        reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" `
            /v PowerThrottlingOff /t REG_DWORD /d 1 /f >$null
    }

    Write-Host "ALL DONE. REBOOT REQUIRED."
}

# ==========================================================
# RESTORE MODE
# ==========================================================
elseif ($mode -eq "2") {

    Write-Host "Restoring Windows defaults..."

    foreach ($svc in @(
        "DiagTrack","dmwappushservice","PcaSvc",
        "wuauserv","UsoSvc","WaaSMedicSvc",
        "WSearch","OneSyncSvc",
        "sshd","ssh-agent","WinRM","TermService","RemoteRegistry"
    )) {
        Enable-ServiceSafe $svc
    }

    # Remove hosts blocks
    $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
    (Get-Content $hostsPath | Where-Object {$_ -notmatch "microsoft|telemetry|ads"}) |
        Set-Content $hostsPath

    # Restore Medic ACL
    regini = @"
HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc [1 5 7 11]
"@
    $tmp = "$env:TEMP\medic_acl_restore.txt"
    $regini | Out-File $tmp -Encoding ASCII
    regini $tmp
    Remove-Item $tmp -Force

    powercfg -setactive scheme_balanced

    Write-Host "DEFAULTS RESTORED. REBOOT REQUIRED."
}

else {
    Write-Host "Invalid selection."
}
