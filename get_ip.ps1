# Script to find your laptop's IP address for Arduino configuration
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  SMART PENDANT - IP ADDRESS FINDER" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Finding your WiFi IP address...`n" -ForegroundColor Yellow

# Get WiFi adapter IP
$ipAddress = Get-NetIPAddress -AddressFamily IPv4 | 
    Where-Object { $_.InterfaceAlias -like "*Wi-Fi*" -or $_.InterfaceAlias -like "*Wireless*" } |
    Select-Object -First 1 -ExpandProperty IPAddress

if ($ipAddress) {
    Write-Host "✅ Your WiFi IP Address: " -NoNewline -ForegroundColor Green
    Write-Host $ipAddress -ForegroundColor White -BackgroundColor DarkGreen
    
    Write-Host "`n📝 NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "1. Open arduino\smart_pendant_wifi\smart_pendant_wifi.ino"
    Write-Host "2. Change this line:" -ForegroundColor Cyan
    Write-Host "   const char* SERVER_URL = `"http://$ipAddress:3000`";" -ForegroundColor White
    Write-Host "`n3. Also update .env file:" -ForegroundColor Cyan
    Write-Host "   API_BASE_URL=http://$ipAddress:3000/api"
    Write-Host "   WS_URL=ws://$ipAddress:3000"
    
    Write-Host "`n🚀 Then run:" -ForegroundColor Yellow
    Write-Host "   cd backend"
    Write-Host "   npm install"
    Write-Host "   npm start"
    
    # Copy to clipboard
    $ipAddress | Set-Clipboard
    Write-Host "`n✅ IP address copied to clipboard!" -ForegroundColor Green
    
} else {
    Write-Host "❌ Could not find WiFi IP address" -ForegroundColor Red
    Write-Host "Try running: ipconfig" -ForegroundColor Yellow
    Write-Host "Look for 'IPv4 Address' under your WiFi adapter`n"
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
