# Find Arduino ESP32 on Network
# This script scans your network for the Arduino ESP32

Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  🔍 Finding Arduino ESP32 on Network                 ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Get local IP address
$localIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi-Fi*" | Where-Object {$_.IPAddress -match "192.168"}).IPAddress

if (-not $localIP) {
    $localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -match "192.168"}).IPAddress
}

if (-not $localIP) {
    Write-Host "❌ Could not find local IP address" -ForegroundColor Red
    exit 1
}

Write-Host "📡 Your computer's IP: $localIP" -ForegroundColor Green

# Extract network prefix (e.g., 192.168.0)
$networkPrefix = $localIP -replace '\.\d+$', ''

Write-Host "🔍 Scanning network: $networkPrefix.0/24" -ForegroundColor Yellow
Write-Host "   This may take 1-2 minutes...`n" -ForegroundColor Gray

$found = $false
$arduinoIP = $null

# Scan common IP range (1-254)
for ($i = 1; $i -le 254; $i++) {
    $ip = "$networkPrefix.$i"
    
    # Skip your own IP
    if ($ip -eq $localIP) {
        continue
    }
    
    # Show progress every 50 IPs
    if ($i % 50 -eq 0) {
        Write-Host "   Scanned up to $ip..." -ForegroundColor Gray
    }
    
    # Try to connect to port 80 (Arduino web server)
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    try {
        $connection = $tcpClient.BeginConnect($ip, 80, $null, $null)
        $wait = $connection.AsyncWaitHandle.WaitOne(100, $false) # 100ms timeout
        
        if ($wait) {
            $tcpClient.EndConnect($connection)
            
            # Try to fetch /audio endpoint to verify it's Arduino
            try {
                $response = Invoke-WebRequest -Uri "http://$ip/" -TimeoutSec 2 -ErrorAction SilentlyContinue
                
                Write-Host "`n✅ Found device at $ip (port 80 open)" -ForegroundColor Green
                Write-Host "   Testing if it's Arduino..." -ForegroundColor Yellow
                
                # This is likely the Arduino!
                $arduinoIP = $ip
                $found = $true
                break
                
            } catch {
                Write-Host "   Device at $ip (port 80 open but not responding to HTTP)" -ForegroundColor Gray
            }
        }
    } catch {
        # Connection failed, move on
    } finally {
        $tcpClient.Close()
    }
}

Write-Host ""

if ($found -and $arduinoIP) {
    Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║  ✅ Arduino ESP32 Found!                              ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host "   IP Address: $arduinoIP" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📝 Next Steps:" -ForegroundColor Yellow
    Write-Host "   1. Update backend/server.js line 266:" -ForegroundColor White
    Write-Host "      const arduinoIp = process.env.ARDUINO_IP || '$arduinoIP';" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   2. Or set environment variable:" -ForegroundColor White
    Write-Host "      `$env:ARDUINO_IP = '$arduinoIP'" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   3. Restart backend server" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║  ❌ Arduino ESP32 Not Found                           ║" -ForegroundColor Red
    Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 Troubleshooting:" -ForegroundColor Yellow
    Write-Host "   1. Make sure Arduino is powered on" -ForegroundColor White
    Write-Host "   2. Check Arduino Serial Monitor for IP address" -ForegroundColor White
    Write-Host "   3. Ensure Arduino is connected to WiFi: ZTE_Callie" -ForegroundColor White
    Write-Host "   4. Manually update backend/server.js with Arduino IP" -ForegroundColor White
    Write-Host ""
}
