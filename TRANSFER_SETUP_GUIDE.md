# 🚀 Smart Pendant App - Transfer Setup Guide

Complete guide for setting up the Smart Pendant mobile app and backend server on a new laptop.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Transfer Files](#transfer-files)
3. [Backend Server Setup](#backend-server-setup)
4. [Mobile App Setup](#mobile-app-setup)
5. [Network Configuration](#network-configuration)
6. [Testing & Verification](#testing--verification)
7. [Troubleshooting](#troubleshooting)

---

## 1️⃣ Prerequisites

### **Software to Install on New Laptop**

#### **A. Node.js (for Backend Server)**
1. Download from: https://nodejs.org/
2. Install **LTS version** (recommended: v18.x or v20.x)
3. Verify installation:
   ```powershell
   node --version
   npm --version
   ```

#### **B. Flutter SDK (for Mobile App)**
1. Download from: https://flutter.dev/docs/get-started/install/windows
2. Extract to: `C:\src\flutter`
3. Add to PATH:
   - Open System Environment Variables
   - Add `C:\src\flutter\bin` to PATH
4. Verify installation:
   ```powershell
   flutter --version
   flutter doctor
   ```

#### **C. Android Studio (for Mobile Development)**
1. Download from: https://developer.android.com/studio
2. Install with:
   - Android SDK
   - Android SDK Command-line Tools
   - Android Emulator (optional)
3. Set up Android SDK path in Flutter:
   ```powershell
   flutter config --android-sdk "C:\Users\YourName\AppData\Local\Android\Sdk"
   ```

#### **D. Git (Optional but Recommended)**
1. Download from: https://git-scm.com/
2. Install with default settings

#### **E. Visual Studio Code (Recommended IDE)**
1. Download from: https://code.visualstudio.com/
2. Install extensions:
   - Flutter
   - Dart
   - Node.js Extension Pack

---

## 2️⃣ Transfer Files

### **Method 1: USB Flash Drive**

Copy the entire project folder to USB drive:
```
smart_pendant_app/
```

Transfer to new laptop at:
```
C:\smart_pendant_app\
```

### **Method 2: Cloud Storage (Google Drive, OneDrive)**

1. Compress the project folder
2. Upload to cloud
3. Download on new laptop
4. Extract to `C:\smart_pendant_app\`

### **Method 3: GitHub (Recommended)**

On old laptop:
```powershell
cd C:\smart_pendant_app
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/yourusername/smart-pendant-app.git
git push -u origin main
```

On new laptop:
```powershell
cd C:\
git clone https://github.com/yourusername/smart-pendant-app.git
```

---

## 3️⃣ Backend Server Setup

### **Step 1: Navigate to Backend Folder**

```powershell
cd C:\smart_pendant_app\backend
```

### **Step 2: Install Dependencies**

```powershell
npm install
```

This will install:
- express
- ws (WebSocket)
- cors
- And other dependencies from `package.json`

### **Step 3: Verify Backend Files**

Check that these files exist:
- ✅ `package.json`
- ✅ `server.js`
- ✅ `test_server.js`
- ✅ `README.md`

### **Step 4: Test Backend Server**

Start the server:
```powershell
node server.js
```

Expected output:
```
🚀 Smart Pendant Backend Server
📡 HTTP Server running on port 3000
🔌 WebSocket Server ready
```

**Keep this terminal open!** Press `Ctrl+C` to stop when done testing.

### **Step 5: Create Start Script (Optional)**

The project already has `start_backend.bat`. Double-click it to start the server quickly.

Or create a PowerShell script `start_backend.ps1`:
```powershell
# Save this as: C:\smart_pendant_app\start_backend.ps1
cd backend
node server.js
```

---

## 4️⃣ Mobile App Setup

### **Step 1: Navigate to Project Root**

```powershell
cd C:\smart_pendant_app
```

### **Step 2: Install Flutter Dependencies**

```powershell
flutter pub get
```

This will download all packages from `pubspec.yaml`:
- google_maps_flutter
- geolocator
- provider
- http
- web_socket_channel
- And many more...

### **Step 3: Verify Flutter Configuration**

```powershell
flutter doctor
```

Fix any issues reported (especially Android toolchain).

### **Step 4: Check for Platform-Specific Setup**

#### **Android:**
```powershell
flutter doctor --android-licenses
```
Accept all licenses.

#### **iOS (if you have Mac):**
```powershell
flutter doctor
```
Follow Xcode setup instructions.

---

## 5️⃣ Network Configuration

### **⚠️ CRITICAL: Update IP Addresses**

You MUST update the IP address of the new laptop in 3 places:

### **A. Find New Laptop's IP Address**

```powershell
ipconfig | findstr /i "IPv4"
```

Or:
```powershell
(Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Wi-Fi).IPAddress
```

Example output: `192.168.1.100`

### **B. Update Files with New IP**

#### **1. Mobile App `.env` file**

Edit: `C:\smart_pendant_app\.env`

```properties
API_BASE_URL=http://192.168.1.100:3000/api
WS_URL=ws://192.168.1.100:3000
GOOGLE_MAPS_API_KEY=AIzaSyDIRIKuP7sSpx3HCIv82UPPSS6PEdCAxXw
```

Replace `192.168.1.100` with YOUR new laptop IP.

#### **2. Camera Provider (Hardcoded)**

Edit: `C:\smart_pendant_app\lib\providers\camera_provider.dart`

Line 19:
```dart
static const String SERVER_URL = 'http://192.168.1.100:3000';
```

Replace with your new IP.

#### **3. Arduino Code**

Edit: `C:\smart_pendant_app\arduino\smart_pendant_wifi\smart_pendant_wifi.ino`

Line 24:
```cpp
const char* SERVER_URL = "http://192.168.1.100:3000";
```

Replace with your new IP, then re-upload to Arduino.

### **C. Configure Windows Firewall**

Allow port 3000 through firewall:

```powershell
# Run as Administrator
New-NetFirewallRule -DisplayName "Smart Pendant Backend" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow
```

Or use the provided script:
```powershell
# Run as Administrator
.\allow_firewall.ps1
```

---

## 6️⃣ Testing & Verification

### **Test 1: Backend Server**

1. **Start backend:**
   ```powershell
   cd C:\smart_pendant_app\backend
   node server.js
   ```

2. **Test in browser:**
   Open: `http://localhost:3000/`
   
   Should see: "Smart Pendant Backend API"

3. **Test from phone:**
   Open browser on phone, navigate to:
   `http://YOUR_LAPTOP_IP:3000/`

### **Test 2: Mobile App**

1. **Connect phone via USB** (enable USB debugging)

2. **Check device:**
   ```powershell
   flutter devices
   ```

3. **Run app:**
   ```powershell
   flutter run
   ```

4. **Or build APK:**
   ```powershell
   flutter build apk --release
   ```
   APK location: `build\app\outputs\flutter-apk\app-release.apk`

### **Test 3: WebSocket Connection**

1. Backend server must be running
2. Open mobile app
3. Check backend terminal for:
   ```
   📱 Flutter app connected
   👥 Total connected clients: 1
   ```

### **Test 4: Arduino Connection**

1. Ensure Arduino, laptop, and phone are on **same WiFi network**
2. Arduino should print:
   ```
   ✅ WiFi Connected!
   📍 IP Address: 192.168.1.XXX
   ```
3. Arduino should successfully send telemetry to server

---

## 7️⃣ Troubleshooting

### **Problem: "Connection Refused" from Mobile App**

**Solutions:**
1. ✅ Check backend server is running (`node server.js`)
2. ✅ Verify laptop firewall allows port 3000
3. ✅ Confirm laptop and phone on same WiFi
4. ✅ Update IP address in `.env` file
5. ✅ Restart Flutter app after changing `.env`

---

### **Problem: "flutter: command not found"**

**Solutions:**
1. ✅ Verify Flutter is installed: `flutter --version`
2. ✅ Add Flutter to PATH:
   - `C:\src\flutter\bin`
3. ✅ Restart terminal/PowerShell
4. ✅ Run: `flutter doctor` to verify

---

### **Problem: "pub get failed"**

**Solutions:**
1. ✅ Check internet connection
2. ✅ Clear pub cache:
   ```powershell
   flutter pub cache repair
   ```
3. ✅ Delete `pubspec.lock` and retry:
   ```powershell
   del pubspec.lock
   flutter pub get
   ```

---

### **Problem: "npm install failed"**

**Solutions:**
1. ✅ Check Node.js version: `node --version`
2. ✅ Clear npm cache:
   ```powershell
   npm cache clean --force
   ```
3. ✅ Delete `node_modules` and retry:
   ```powershell
   rm -r node_modules
   npm install
   ```

---

### **Problem: Google Maps not showing**

**Solutions:**
1. ✅ Verify API key in `.env` file
2. ✅ Enable required APIs in Google Cloud Console:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Geocoding API
3. ✅ Add API key restrictions (optional)

---

### **Problem: Arduino can't connect to WiFi**

**Solutions:**
1. ✅ Update WiFi credentials in Arduino code (lines 22-23)
2. ✅ Ensure WiFi is 2.4GHz (not 5GHz - ESP32 doesn't support 5GHz)
3. ✅ Check WiFi password is correct
4. ✅ Verify router allows new devices

---

### **Problem: Build errors in Flutter**

**Solutions:**
1. ✅ Run `flutter clean`
2. ✅ Run `flutter pub get`
3. ✅ Update Flutter SDK:
   ```powershell
   flutter upgrade
   ```
4. ✅ Check Android SDK is properly configured:
   ```powershell
   flutter doctor --android-licenses
   ```

---

## 📝 Quick Reference Commands

### **Backend Server**
```powershell
# Start server
cd C:\smart_pendant_app\backend
node server.js

# Test server
curl http://localhost:3000
```

### **Mobile App**
```powershell
# Install dependencies
flutter pub get

# Run on connected device
flutter run

# Build release APK
flutter build apk --release

# Clean build cache
flutter clean
```

### **Network**
```powershell
# Get laptop IP
ipconfig | findstr /i "IPv4"

# Test connectivity
ping YOUR_LAPTOP_IP
```

---

## 🎯 Checklist for New Setup

### **Before Starting:**
- [ ] Node.js installed
- [ ] Flutter SDK installed
- [ ] Android Studio installed
- [ ] All files transferred to new laptop

### **Backend Setup:**
- [ ] `npm install` completed successfully
- [ ] Server starts without errors
- [ ] Port 3000 allowed in firewall
- [ ] Can access `http://localhost:3000` in browser

### **Mobile App Setup:**
- [ ] `flutter pub get` completed successfully
- [ ] `flutter doctor` shows no critical issues
- [ ] `.env` file updated with new IP address
- [ ] `camera_provider.dart` updated with new IP

### **Network Configuration:**
- [ ] New laptop IP address identified
- [ ] IP updated in `.env`
- [ ] IP updated in `camera_provider.dart`
- [ ] IP updated in Arduino code (if applicable)
- [ ] Firewall configured to allow port 3000

### **Testing:**
- [ ] Backend server responds to HTTP requests
- [ ] Mobile app connects to backend
- [ ] WebSocket connection established
- [ ] Arduino can send telemetry (if hardware available)

---

## 🚀 First-Time Setup Script

Save this as `setup.ps1` and run as Administrator:

```powershell
# Smart Pendant - First-Time Setup Script
# Run this script as Administrator on new laptop

Write-Host "🚀 Smart Pendant Setup" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

# Step 1: Check Node.js
Write-Host "`n📦 Checking Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js installed: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js not found! Install from https://nodejs.org/" -ForegroundColor Red
    exit 1
}

# Step 2: Check Flutter
Write-Host "`n🎯 Checking Flutter..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version
    Write-Host "✅ Flutter installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Flutter not found! Install from https://flutter.dev/" -ForegroundColor Red
    exit 1
}

# Step 3: Install Backend Dependencies
Write-Host "`n📡 Installing backend dependencies..." -ForegroundColor Yellow
Set-Location backend
npm install
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Backend dependencies installed" -ForegroundColor Green
} else {
    Write-Host "❌ Backend installation failed!" -ForegroundColor Red
}
Set-Location ..

# Step 4: Install Flutter Dependencies
Write-Host "`n📱 Installing Flutter dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Flutter dependencies installed" -ForegroundColor Green
} else {
    Write-Host "❌ Flutter installation failed!" -ForegroundColor Red
}

# Step 5: Configure Firewall
Write-Host "`n🔥 Configuring Windows Firewall..." -ForegroundColor Yellow
try {
    New-NetFirewallRule -DisplayName "Smart Pendant Backend" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow -ErrorAction Stop
    Write-Host "✅ Firewall rule added" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Firewall rule may already exist or admin rights needed" -ForegroundColor Yellow
}

# Step 6: Get IP Address
Write-Host "`n🌐 Your laptop IP address:" -ForegroundColor Yellow
$ip = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias Wi-Fi).IPAddress
Write-Host "   $ip" -ForegroundColor Cyan

# Step 7: Instructions
Write-Host "`n✅ Setup Complete!" -ForegroundColor Green
Write-Host "`n📝 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Update .env file with IP: $ip" -ForegroundColor White
Write-Host "   2. Update lib/providers/camera_provider.dart with IP: $ip" -ForegroundColor White
Write-Host "   3. Update Arduino code with IP: $ip (if applicable)" -ForegroundColor White
Write-Host "   4. Run backend: cd backend; node server.js" -ForegroundColor White
Write-Host "   5. Run mobile app: flutter run" -ForegroundColor White

Write-Host "`n🎉 Happy coding!" -ForegroundColor Cyan
```

Run it:
```powershell
# Run as Administrator
.\setup.ps1
```

---

## 📞 Support

If you encounter issues:
1. Check this guide's **Troubleshooting** section
2. Run `flutter doctor` for Flutter issues
3. Check backend server logs for errors
4. Verify network connectivity between devices

---

**Last Updated:** November 5, 2025
**Version:** 1.0
