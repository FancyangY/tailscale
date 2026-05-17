$ErrorActionPreference = "Stop"

$InstallDir = Join-Path $env:ProgramFiles "Tailscale"
$Tailscale = Join-Path $InstallDir "tailscale.exe"

if (-not (Test-Path -LiteralPath $Tailscale)) {
    throw "tailscale.exe not found at $Tailscale"
}

Write-Host "Version:"
& $Tailscale version | Out-Host

Write-Host ""
Write-Host "Netcheck:"
& $Tailscale netcheck | Out-Host

Write-Host ""
Write-Host "Debug portmap:"
& $Tailscale debug portmap --type upnp --duration 5s --log-http | Out-Host

Write-Host ""
Write-Host "Published self endpoints:"
$statusRaw = & $Tailscale status --json
if ($LASTEXITCODE -ne 0) {
    throw "tailscale status --json failed"
}
$status = $statusRaw | ConvertFrom-Json
if ($status.Self.Addrs) {
    $status.Self.Addrs | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "  No self endpoints published in status JSON."
}
