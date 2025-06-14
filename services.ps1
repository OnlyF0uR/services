# Self-elevate *only if double-clicked or not already running as admin*
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {

    $hostUI = $Host.UI.RawUI.WindowTitle
    $isTerminalHost = $hostUI -ne $null -and $hostUI.Trim() -ne ""

    if ($isTerminalHost) {
        Write-Host "[!] Please run this script as Administrator." -ForegroundColor Yellow
        pause
        exit
    } else {
        # Likely double-clicked — elevate and launch new window
        Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"" -Verb RunAs
        exit
    }
}

function Get-ServiceStatus($name) {
    $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
    if (-not $svc) { return "[?] Not Found" }
    elseif ($svc.Status -eq "Running") { return "[+] Running" }
    elseif ($svc.Status -eq "Stopped") { return "[-] Stopped" }
    else { return "[!] $($svc.Status)" }
}

function Manage-Service($name) {
    $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
    if (-not $svc) {
        Write-Host "[-] Service '$name' not found." -ForegroundColor Red
        return
    }

    try {
        if ($svc.Status -eq "Running") {
            Write-Host "[*] Stopping and disabling '$name'..." -ForegroundColor Yellow
            Stop-Service -Name $name -Force -ErrorAction Stop
            Set-Service -Name $name -StartupType Disabled -ErrorAction Stop
            Write-Host "[+] Service '$name' stopped and disabled." -ForegroundColor Green
        } else {
            Write-Host "[*] Starting and enabling '$name'..." -ForegroundColor Yellow
            Set-Service -Name $name -StartupType Automatic -ErrorAction Stop
            Start-Service -Name $name -ErrorAction Stop
            Write-Host "[+] Service '$name' started and enabled." -ForegroundColor Green
        }
    } catch {
        Write-Host "[-] Error managing service '$name': $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Prompt-Menu {
    do {
        $pgStatus = Get-ServiceStatus -name "postgresql-x64-17"
        $mariadbStatus = Get-ServiceStatus -name "MariaDB"

        Clear-Host
        Write-Host "*** Select the database service to toggle: ***`n"
        Write-Host "1. PostgreSQL (postgresql-x64-17) - $pgStatus"
        Write-Host "2. MariaDB (MariaDB)             - $mariadbStatus"
        Write-Host "3. Exit`n"

        $choice = Read-Host "Enter choice (1-3)"
        switch ($choice) {
            '1' { 
                Manage-Service -name "postgresql-x64-17"
                Write-Host "`nPress any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            '2' { 
                Manage-Service -name "MariaDB"
                Write-Host "`nPress any key to continue..."
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            }
            '3' { 
                Write-Host "`nExiting..."
                return
            }
            default {
                Write-Host "`nInvalid choice. Please enter 1, 2, or 3." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($choice -ne '3')
}

Prompt-Menu
