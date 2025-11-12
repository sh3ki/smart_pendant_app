# Quick IP Address Finder for Smart Pendant
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SMART PENDANT - IP ADDRESS FINDER" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get WiFi adapter IP
$ipAddress = Get-NetIPAddress -AddressFamily IPv4 | 
    Where-Object { $_.InterfaceAlias -like "*Wi-Fi*" -or $_.InterfaceAlias -like "*Wireless*" } |
    Select-Object -First 1 -ExpandProperty IPAddress

if ($ipAddress) {
    Write-Host "SUCCESS! Your WiFi IP Address: " -NoNewline -ForegroundColor Green
    Write-Host $ipAddress -ForegroundColor White -BackgroundColor DarkGreen
    
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "1. Open arduino\smart_pendant_wifi\smart_pendant_wifi.ino"
    Write-Host "2. Change line 17 to:" -ForegroundColor Cyan
    Write-Host "   const char* SERVER_URL = `"http://$ipAddress`:3000`";" -ForegroundColor White
    
    Write-Host ""
    Write-Host "Then start the backend:" -ForegroundColor Yellow
    Write-Host "   cd backend"
    Write-Host "   npm install"
    Write-Host "   npm start"
    
    # Copy to clipboard
    try {
        $ipAddress | Set-Clipboard
        Write-Host ""
        Write-Host "IP address copied to clipboard!" -ForegroundColor Green
    } catch {
        Write-Host ""
        Write-Host "Copy this IP address: $ipAddress" -ForegroundColor Yellow
    }
    
} else {
    Write-Host "ERROR: Could not find WiFi IP address" -ForegroundColor Red
    Write-Host ""
    Write-Host "Try running: ipconfig" -ForegroundColor Yellow
    Write-Host "Look for 'IPv4 Address' under your WiFi adapter"
}

Write-Host ""
