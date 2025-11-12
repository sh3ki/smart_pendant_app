# 🚀 QUICK START GUIDE: Arduino to Flutter App

## 📋 **STEP-BY-STEP INSTRUCTIONS**

### ✅ **Step 1: Get Your Laptop's IP Address**

#### On Windows PowerShell:
```powershell
ipconfig
```
Look for **"IPv4 Address"** under your WiFi adapter (e.g., `192.168.1.100`)

#### On Mac/Linux:
```bash
ifconfig | grep "inet "
```

📝 **Write down your IP address:** `__________________`

---

### ✅ **Step 2: Start the Backend Server**

1. Open PowerShell/Terminal
2. Navigate to backend folder:
   ```powershell
   cd c:\smart_pendant_app\backend
   ```

3. Install dependencies (first time only):
   ```powershell
   npm install
   ```

4. Start the server:
   ```powershell
   npm start
   ```

✅ You should see:
```
🚀 Smart Pendant Backend Server Running
📡 HTTP API:      http://localhost:3000
🔌 WebSocket:     ws://localhost:3000
```

**⚠️ Keep this terminal window open!**

---

### ✅ **Step 3: Configure Arduino Code**

1. Open `arduino/smart_pendant_wifi/smart_pendant_wifi.ino` in Arduino IDE

2. **Change these lines** (around line 15-17):
   ```cpp
   const char* WIFI_SSID = "YOUR_WIFI_NAME";        // ⬅️ Your WiFi name
   const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD"; // ⬅️ Your WiFi password
   const char* SERVER_URL = "http://192.168.1.100:3000"; // ⬅️ Your laptop IP from Step 1
   ```

3. **Example:**
   ```cpp
   const char* WIFI_SSID = "Home_WiFi_5G";
   const char* WIFI_PASSWORD = "MySecurePassword123";
   const char* SERVER_URL = "http://192.168.1.100:3000";
   ```

---

### ✅ **Step 4: Upload to Arduino Nano ESP32**

1. Connect Arduino Nano ESP32 to your laptop via USB-C

2. In Arduino IDE:
   - **Tools > Board** → "Arduino Nano ESP32"
   - **Tools > Port** → Select the COM port (e.g., COM3)
   
3. Click **Upload** (➡️ button)

4. Open **Serial Monitor** (Ctrl+Shift+M):
   - Set baud rate to **115200**
   
5. ✅ You should see:
   ```
   📶 Connecting to WiFi: Home_WiFi_5G
   .....
   ✅ WiFi Connected!
   📍 IP Address: 192.168.1.150
   🔧 Initializing ADXL345... ✅ ADXL345 OK
   📡 GPS Serial initialized on D4/D5
   ✅ Setup complete! Starting main loop...
   
   📤 Telemetry sent: 200 | Activity: IDLE | Accel: 0.02, -0.01, 1.00
   ```

---

### ✅ **Step 5: Update Flutter App Configuration**

1. Open `c:\smart_pendant_app\.env` file

2. Change the IP address to your laptop's IP from Step 1:
   ```
   API_BASE_URL=http://192.168.1.100:3000/api
   WS_URL=ws://192.168.1.100:3000
   ```

---

### ✅ **Step 6: Run the Flutter App**

1. Make sure your Android emulator is running:
   ```powershell
   flutter run -d emulator-5554
   ```

2. ✅ The app should launch and show:
   - **Online** status (green check)
   - **Live location** updating
   - **Activity** type (IDLE, WALK, RUN)
   - **Battery %**
   - **Accelerometer** data

---

## 🧪 **Testing the Connection**

### Test 1: Check Backend Logs
In the backend terminal, you should see:
```
📡 Telemetry from Arduino: { deviceId: 'pendant-1', battery: 75, ... }
📱 Flutter app connected
```

### Test 2: Press Panic Button
1. Press the button connected to **D7** on your Arduino
2. You should hear a beep from the speaker (PAM8403)
3. Arduino Serial Monitor shows: `🚨🚨🚨 PANIC BUTTON PRESSED! 🚨🚨🚨`
4. **Flutter app shows alert screen** with location!

### Test 3: Live Telemetry
1. **Shake the Arduino** (move the ADXL345 sensor)
2. Watch the **Activity** card in the app change:
   - No movement → **IDLE**
   - Gentle shake → **WALK**
   - Strong shake → **RUN**

---

## 🐛 **Troubleshooting**

### ❌ Arduino won't connect to WiFi
**Solution:**
- Double-check `WIFI_SSID` and `WIFI_PASSWORD` (case-sensitive!)
- Make sure you're using **2.4GHz WiFi** (ESP32 doesn't support 5GHz)
- Check if your router has MAC address filtering enabled

### ❌ "HTTP Error: -1" in Arduino Serial Monitor
**Solution:**
- Verify your laptop's IP address hasn't changed
- Make sure backend server is running
- Test backend manually:
  ```powershell
  curl http://192.168.1.100:3000/health
  ```

### ❌ Flutter app shows "Offline"
**Solution:**
- Check `.env` file has correct IP address
- Restart the Flutter app:
  ```powershell
  flutter run -d emulator-5554
  ```
- Make sure backend server is running

### ❌ ADXL345 Error
**Solution:**
- Check I2C wiring:
  - **SDA** → A4 (GPIO18)
  - **SCL** → A5 (GPIO19)
  - **VCC** → 3.3V
  - **GND** → GND
- Try running I2C scanner sketch first

### ❌ GPS not working
**Solution:**
- GPS needs clear sky view (won't work indoors)
- Wait 1-3 minutes for GPS to get satellite lock
- Check wiring:
  - **GPS TX** → D5 (Arduino RX)
  - **GPS RX** → D4 (Arduino TX)

---

## 📊 **Data Flow Diagram**

```
┌─────────────────────────────────────────────────────────────┐
│  ARDUINO NANO ESP32                                         │
│  ├─ ADXL345 (Motion) ────→ I2C (A4/A5)                      │
│  ├─ GPS L80 (Location) ───→ Serial1 (D4/D5)                 │
│  ├─ Panic Button ─────────→ D7                              │
│  └─ WiFi Module ──────────→ Sends JSON via HTTP POST        │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    HTTP POST every 5 seconds
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  BACKEND SERVER (Node.js)                                   │
│  ├─ Receives telemetry from Arduino                         │
│  ├─ Stores latest device state                              │
│  └─ Broadcasts via WebSocket to Flutter app                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    WebSocket (real-time)
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  FLUTTER APP (Android Emulator)                             │
│  ├─ Shows live location on map                              │
│  ├─ Displays activity type (IDLE/WALK/RUN)                  │
│  ├─ Shows battery & signal strength                         │
│  └─ Alerts on panic button press                            │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 **Next Steps After Testing**

Once everything is working:

1. ✅ **Add camera capture** (OV7670)
2. ✅ **Improve GPS parsing** (full NMEA support)
3. ✅ **Add geofencing** (alert if child leaves area)
4. ✅ **Battery monitoring** (read actual battery voltage)
5. ✅ **Deploy to real phone** (not just emulator)
6. ✅ **Cloud hosting** (so it works outside your home WiFi)

---

## 📞 **Need Help?**

If you get stuck at any step:
1. Check the **Serial Monitor** on Arduino (115200 baud)
2. Check the **backend server logs** in terminal
3. Check **Flutter app logs** (`flutter logs`)
4. Take a screenshot and describe what's not working!

---

**🎉 YOU'RE READY TO GO! Start with Step 1 and follow in order. Good luck! 🚀**
