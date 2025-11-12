# Run this script as Administrator to allow Node.js through Windows Firewall
# Right-click this file and select "Run with PowerShell (Admin)"

Write-Host "================================" -ForegroundColor Cyan
Write-Host "Smart Pendant Firewall Setup" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Right-click this file and select 'Run with PowerShell (Admin)'" -ForegroundColor Yellow
    Write-Host ""
    Pause
    exit 1
}

Write-Host "Running as Administrator... OK" -ForegroundColor Green
Write-Host ""

# Remove old rules if they exist
Write-Host "Removing old firewall rules..." -ForegroundColor Yellow
netsh advfirewall firewall delete rule name="Node.js Server" >$null 2>&1
netsh advfirewall firewall delete rule name="Smart Pendant Backend" >$null 2>&1

# Add new firewall rules
Write-Host "Adding firewall rule for TCP port 3000..." -ForegroundColor Yellow
netsh advfirewall firewall add rule name="Smart Pendant Backend" dir=in action=allow protocol=TCP localport=3000

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "SUCCESS! Firewall configured correctly!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Port 3000 is now open for:" -ForegroundColor Cyan
    Write-Host "  - Arduino connections" -ForegroundColor White
    Write-Host "  - Flutter app connections" -ForegroundColor White
    Write-Host ""
    Write-Host "You can now start the server with:" -ForegroundColor Cyan
    Write-Host "  cd backend" -ForegroundColor White
    Write-Host "  node server.js" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "ERROR: Failed to add firewall rule" -ForegroundColor Red
    Write-Host ""
}

Write-Host "Press any key to close..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
