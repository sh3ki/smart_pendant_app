# ✅ COMPLETE SETUP CHECKLIST

Use this checklist to track your progress connecting Arduino to the Flutter app.

---

## 🔧 **PRE-REQUISITES**

- [ ] Arduino Nano ESP32 connected via USB
- [ ] Arduino IDE installed with ESP32 board support
- [ ] Node.js installed (check: `node --version`)
- [ ] Flutter installed and working
- [ ] Android emulator running (`emulator-5554`)
- [ ] All hardware components wired (see ANDROID_BUILD_ISSUE.md)

---

## 📡 **STEP 1: NETWORK SETUP**

### Find Your Laptop's IP Address

**Option A: Use the PowerShell script**
```powershell
cd c:\smart_pendant_app
.\get_ip.ps1
```

**Option B: Manual check**
```powershell
ipconfig
```
Look for "IPv4 Address" under your WiFi adapter.

- [ ] IP Address found: `___________________________`
- [ ] IP Address copied to clipboard

---

## 🖥️ **STEP 2: BACKEND SERVER**

### Install Dependencies
```powershell
cd c:\smart_pendant_app\backend
npm install
```

- [ ] Dependencies installed (express, ws, cors)

### Start Server
```powershell
npm start
```

Expected output:
```
🚀 Smart Pendant Backend Server Running
📡 HTTP API:      http://localhost:3000
🔌 WebSocket:     ws://localhost:3000
```

- [ ] Server is running without errors
- [ ] Terminal shows the startup banner
- [ ] **Keep this terminal open!**

### Test Server (Optional)
Open a NEW terminal:
```powershell
cd c:\smart_pendant_app\backend
node test_server.js
```

- [ ] All tests passed ✅

---

## 🤖 **STEP 3: ARDUINO FIRMWARE**

### Configure WiFi Settings

1. Open file: `c:\smart_pendant_app\arduino\smart_pendant_wifi\smart_pendant_wifi.ino`

2. Edit these lines (around line 15-17):
   ```cpp
   const char* WIFI_SSID = "YOUR_WIFI_NAME";
   const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";
   const char* SERVER_URL = "http://192.168.1.100:3000";
   ```

3. Replace with your actual values:
   ```cpp
   const char* WIFI_SSID = "_________________________";
   const char* WIFI_PASSWORD = "_________________________";
   const char* SERVER_URL = "http://YOUR_IP:3000";
   ```

- [ ] WiFi name configured
- [ ] WiFi password configured
- [ ] Server URL configured with correct IP

### Upload to Arduino

1. Connect Arduino Nano ESP32 via USB-C
2. In Arduino IDE:
   - **Tools > Board** → "Arduino Nano ESP32"
   - **Tools > Port** → Select COM port (e.g., COM3)

- [ ] Correct board selected
- [ ] Correct port selected
- [ ] Click **Upload** (➡️)
- [ ] Upload successful (shows "Done uploading")

### Verify Arduino Output

Open Serial Monitor (Ctrl+Shift+M), set baud to **115200**

Expected output:
```
🚀 Smart Pendant Starting...
📶 Connecting to WiFi: YourWiFiName
.....
✅ WiFi Connected!
📍 IP Address: 192.168.1.150
🔧 Initializing ADXL345... ✅ ADXL345 OK
📡 GPS Serial initialized on D4/D5
✅ Setup complete! Starting main loop...

📤 Telemetry sent: 200 | Activity: IDLE | Accel: 0.02, -0.01, 1.00
```

- [ ] WiFi connected successfully
- [ ] Arduino got an IP address
- [ ] ADXL345 initialized OK
- [ ] Telemetry sending (shows "200" status code)

### Check Backend Logs

Go back to the backend terminal window.

Expected output:
```
📡 Telemetry from Arduino: { deviceId: 'pendant-1', battery: 75, ... }
```

- [ ] Backend is receiving data from Arduino
- [ ] Telemetry appears every 5 seconds

---

## 📱 **STEP 4: FLUTTER APP**

### Update Configuration

1. Open file: `c:\smart_pendant_app\.env`

2. Change to your laptop's IP:
   ```
   API_BASE_URL=http://192.168.1.100:3000/api
   WS_URL=ws://192.168.1.100:3000
   ```

- [ ] `.env` file updated with correct IP

### Run the App

Make sure Android emulator is running:
```powershell
cd c:\smart_pendant_app
flutter run -d emulator-5554
```

- [ ] App launched successfully
- [ ] No build errors

### Verify App Display

Check these elements in the app:

- [ ] Status shows **"Online"** with green checkmark
- [ ] Battery percentage displays (e.g., "75%")
- [ ] "Last seen" timestamp is recent
- [ ] Location shows on map
- [ ] Activity type displays (IDLE, WALK, RUN)

### Check WebSocket Connection

In backend terminal, you should see:
```
📱 Flutter app connected
```

- [ ] Backend shows Flutter app connection
- [ ] Data updates in real-time

---

## 🧪 **STEP 5: FUNCTIONALITY TESTS**

### Test 1: Live Telemetry

1. Keep the app open
2. Watch the Arduino Serial Monitor
3. Every 5 seconds, you should see:
   - Arduino sends data (Serial Monitor shows "📤 Telemetry sent: 200")
   - Backend receives data (backend terminal shows "📡 Telemetry from Arduino")
   - App updates (location/activity changes)

- [ ] Telemetry updates every 5 seconds
- [ ] App reflects Arduino data

### Test 2: Motion Detection

1. **Gently shake** the Arduino (move the ADXL345)
2. Watch the Activity card in the app
3. Should change from IDLE → WALK → RUN

Expected Serial Monitor output:
```
📤 Telemetry sent: 200 | Activity: RUN | Accel: 1.23, -0.45, 0.78
```

- [ ] Activity type changes when Arduino moves
- [ ] Accelerometer values change in Serial Monitor

### Test 3: Panic Button

1. **Press the button** connected to D7 on Arduino
2. Watch for:
   - Arduino plays beep sound (1kHz tone)
   - Serial Monitor shows: "🚨🚨🚨 PANIC BUTTON PRESSED! 🚨🚨🚨"
   - Backend shows: "🚨 PANIC BUTTON PRESSED!"
   - **App should show alert screen** (may need to implement alert UI)

- [ ] Button press detected by Arduino
- [ ] Audio tone plays (if speaker connected)
- [ ] Panic alert sent to backend (200 status code)
- [ ] Backend receives panic alert
- [ ] App receives alert via WebSocket

### Test 4: GPS (Optional - needs clear sky)

If GPS has satellite lock:

Expected Serial Monitor output:
```
📤 Telemetry sent: 200 | Activity: IDLE | Accel: 0.00, 0.00, 1.00
Location: 14.5995, 120.9842
```

- [ ] GPS coordinates appear in Serial Monitor
- [ ] Location updates on map in Flutter app

---

## ✅ **SUCCESS CRITERIA**

Mark this section when ALL of the following work:

- [ ] ✅ Arduino connects to WiFi
- [ ] ✅ Arduino sends telemetry every 5 seconds
- [ ] ✅ Backend receives Arduino data
- [ ] ✅ Flutter app shows "Online" status
- [ ] ✅ Location updates on map
- [ ] ✅ Activity type changes with motion
- [ ] ✅ Panic button triggers alert
- [ ] ✅ Data updates in real-time (< 5 second delay)

---

## 🐛 **TROUBLESHOOTING**

### ❌ Arduino won't connect to WiFi

**Symptoms:**
- Serial Monitor shows "..." forever
- Never shows "✅ WiFi Connected!"

**Solutions:**
1. Check SSID and password (case-sensitive!)
2. Make sure it's 2.4GHz WiFi (ESP32 doesn't support 5GHz)
3. Try restarting your router
4. Check if MAC filtering is enabled on router

- [ ] Issue resolved

---

### ❌ Arduino connects but telemetry fails

**Symptoms:**
- WiFi connects OK
- Serial Monitor shows "❌ HTTP Error: -1"

**Solutions:**
1. Verify laptop IP address hasn't changed (run `ipconfig` again)
2. Make sure backend server is still running
3. Try accessing from browser: `http://YOUR_IP:3000/health`
4. Check Windows Firewall isn't blocking port 3000

- [ ] Issue resolved

---

### ❌ ADXL345 initialization fails

**Symptoms:**
- Serial Monitor shows "❌ ADXL345 Error: 2"

**Solutions:**
1. Check I2C wiring:
   - SDA → A4 (GPIO18)
   - SCL → A5 (GPIO19)
   - VCC → 3.3V (NOT 5V!)
   - GND → GND
2. Check for loose connections
3. Try using I2C scanner sketch first

- [ ] Issue resolved

---

### ❌ Flutter app shows "Offline"

**Symptoms:**
- App loads but shows grey "Offline" status
- No data updates

**Solutions:**
1. Check `.env` file has correct IP
2. Restart Flutter app: `flutter run -d emulator-5554`
3. Make sure backend server is running
4. Check Arduino is actually sending data (watch Serial Monitor)

- [ ] Issue resolved

---

### ❌ GPS not getting location

**Symptoms:**
- Default location (San Francisco) never changes

**Solutions:**
1. **GPS needs clear sky view** - won't work indoors
2. Wait 1-5 minutes for initial satellite lock (cold start)
3. Check wiring:
   - GPS TX → Arduino D5
   - GPS RX → Arduino D4
   - VCC → 5V
   - GND → GND
4. For testing indoors, location will remain at default coordinates

- [ ] Issue resolved (or acknowledged for outdoor testing)

---

## 🎉 **YOU'RE DONE!**

If all checkboxes are marked, congratulations! 🎊

Your Smart Pendant system is now:
- ✅ Sending live telemetry
- ✅ Tracking motion/activity
- ✅ Reporting location (when GPS available)
- ✅ Sending panic alerts
- ✅ Updating mobile app in real-time

---

## 📸 **NEXT STEPS**

Now that basic connectivity works, you can:

1. **Add camera capture** (OV7670 integration)
2. **Improve GPS parsing** (better NMEA sentence handling)
3. **Add geofencing** (alert if pendant leaves designated area)
4. **Battery monitoring** (read actual voltage from pin)
5. **Deploy to real Android phone** (not just emulator)
6. **Cloud deployment** (AWS/Heroku for remote access)
7. **Fix SIM7600E** (switch from WiFi to 4G for outdoor use)

---

## 📝 **NOTES**

Write any observations or issues here:

```
______________________________________________________________________

______________________________________________________________________

______________________________________________________________________

______________________________________________________________________
```

---

**Date completed:** ______________

**Time taken:** ______________

**Success?** [ ] YES!  [ ] Not yet (troubleshooting...)
