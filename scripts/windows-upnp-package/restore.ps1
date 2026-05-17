#Requires -RunAsAdministrator
$ErrorActionPreference = "Stop"

$InstallDir = Join-Path $env:ProgramFiles "Tailscale"
$BackupRoot = Join-Path $env:ProgramData "TailscalePatchedBackups"

if (-not (Test-Path -LiteralPath $BackupRoot)) {
    throw "Backup root not found: $BackupRoot"
}

$BackupDir = Get-ChildItem -LiteralPath $BackupRoot -Directory |
    Sort-Object Name -Descending |
    Select-Object -First 1

if ($null -eq $BackupDir) {
    throw "No backup directory found under $BackupRoot"
}

foreach ($name in @("tailscale.exe", "tailscaled.exe")) {
    $path = Join-Path $BackupDir.FullName $name
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Selected backup does not contain $name`: $($BackupDir.FullName)"
    }
}

Write-Host "Restoring from $($BackupDir.FullName)"
Stop-Service -Name Tailscale -Force
Start-Sleep -Seconds 2

foreach ($name in @("tailscale.exe", "tailscaled.exe", "tailscale-ipn.exe", "wintun.dll")) {
    $src = Join-Path $BackupDir.FullName $name
    if (Test-Path -LiteralPath $src) {
        Copy-Item -LiteralPath $src -Destination (Join-Path $InstallDir $name) -Force
    }
}

Start-Service -Name Tailscale
Start-Sleep -Seconds 4

Write-Host "Restored original Tailscale files."
& (Join-Path $InstallDir "tailscale.exe") version | Out-Host
