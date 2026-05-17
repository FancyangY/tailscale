#Requires -RunAsAdministrator
$ErrorActionPreference = "Stop"

$InstallDir = Join-Path $env:ProgramFiles "Tailscale"
$PackageDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackupRoot = Join-Path $env:ProgramData "TailscalePatchedBackups"
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$BackupDir = Join-Path $BackupRoot $Stamp

function Assert-File($Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Required file not found: $Path"
    }
}

Assert-File (Join-Path $PackageDir "bin\tailscale.exe")
Assert-File (Join-Path $PackageDir "bin\tailscaled.exe")
Assert-File $InstallDir

New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

Write-Host "Backing up current Tailscale files to $BackupDir"
foreach ($name in @("tailscale.exe", "tailscaled.exe", "tailscale-ipn.exe", "wintun.dll")) {
    $src = Join-Path $InstallDir $name
    if (Test-Path -LiteralPath $src) {
        Copy-Item -LiteralPath $src -Destination (Join-Path $BackupDir $name) -Force
    }
}

Write-Host "Stopping Tailscale service"
Stop-Service -Name Tailscale -Force
Start-Sleep -Seconds 2

Write-Host "Installing patched binaries"
Copy-Item -LiteralPath (Join-Path $PackageDir "bin\tailscale.exe") -Destination (Join-Path $InstallDir "tailscale.exe") -Force
Copy-Item -LiteralPath (Join-Path $PackageDir "bin\tailscaled.exe") -Destination (Join-Path $InstallDir "tailscaled.exe") -Force

Write-Host "Starting Tailscale service"
Start-Service -Name Tailscale
Start-Sleep -Seconds 4

$Tailscale = Join-Path $InstallDir "tailscale.exe"
Write-Host "Disabling automatic update apply so this patched build is not overwritten"
& $Tailscale set --auto-update=false | Out-Host
if ($LASTEXITCODE -ne 0) {
    Write-Warning "Failed to disable automatic update apply. Run 'tailscale set --auto-update=false' manually."
}

Write-Host ""
Write-Host "Installed patched Tailscale build."
Write-Host "Backup: $BackupDir"
Write-Host ""
Write-Host "Version:"
& $Tailscale version | Out-Host
Write-Host ""
Write-Host "Netcheck:"
& $Tailscale netcheck | Out-Host
