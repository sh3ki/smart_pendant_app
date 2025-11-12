# 🚀 START HERE - Quick Start Guide

Welcome! This guide will help you connect your Arduino Nano ESP32 hardware to your Flutter mobile app.

---

## 📚 **Documentation Overview**

Your workspace now has these helpful documents:

### 🌟 **Essential Documents** (Read These First!)

1. **`SETUP_CHECKLIST.md`** ⭐
   - Step-by-step checklist to track your progress
   - Start here if you want a structured approach
   - Mark off each step as you complete it

2. **`INTEGRATION_GUIDE.md`** ⭐
   - Detailed guide for connecting Arduino → Backend → Flutter
   - Explains data flow and architecture
   - Includes troubleshooting for common issues

3. **`PIN_CONNECTIONS.md`**
   - Visual pinout diagrams
   - Component wiring tables
   - Test code for each component

### 📖 **Reference Documents**

4. **`ANDROID_BUILD_ISSUE.md`**
   - Your original hardware plan and pin mapping
   - Good reference for the overall project goals

5. **`README.md`**
   - Project overview
   - General Flutter app information

---

## ⚡ **Quick Start (5 Steps)**

### 1️⃣ **Get Your IP Address**
```powershell
cd c:\smart_pendant_app
.\get_ip.ps1
```
📋 Write it down: `___________________`

---

### 2️⃣ **Start the Backend Server**
```powershell
cd c:\smart_pendant_app\backend
npm install
npm start
```
✅ Keep this terminal open!

---

### 3️⃣ **Configure & Upload Arduino Code**

Open `arduino/smart_pendant_wifi/smart_pendant_wifi.ino` in Arduino IDE

Change these lines:
```cpp
const char* WIFI_SSID = "YourWiFiName";
const char* WIFI_PASSWORD = "YourWiFiPassword";
const char* SERVER_URL = "http://YOUR_IP:3000";
```

Upload to Arduino Nano ESP32 (Tools → Board → Arduino Nano ESP32)

---

### 4️⃣ **Update Flutter App Config**

Edit `.env` file:
```
API_BASE_URL=http://YOUR_IP:3000/api
WS_URL=ws://YOUR_IP:3000
```

---

### 5️⃣ **Run Flutter App**
```powershell
flutter run -d emulator-5554
```

---

## ✅ **What You Should See**

### Arduino Serial Monitor (115200 baud):
```
✅ WiFi Connected!
📍 IP Address: 192.168.1.150
🔧 Initializing ADXL345... ✅ ADXL345 OK
📤 Telemetry sent: 200 | Activity: IDLE
```

### Backend Terminal:
```
🚀 Smart Pendant Backend Server Running
📡 Telemetry from Arduino: { deviceId: 'pendant-1', ... }
📱 Flutter app connected
```

### Flutter App:
- ✅ "Online" status (green)
- ✅ Battery % displays
- ✅ Location on map
- ✅ Activity type (IDLE/WALK/RUN)

---

## 🧪 **Test It Works**

1. **Shake the Arduino** → Activity changes (IDLE → WALK → RUN)
2. **Press panic button** (D7) → Alert sent, LED blinks, beep sound
3. Watch data update every 5 seconds

---

## 🐛 **If Something Goes Wrong**

### Arduino won't connect to WiFi?
- Check WiFi name/password (case-sensitive!)
- Use 2.4GHz WiFi (not 5GHz)

### Backend says "HTTP Error: -1"?
- Verify IP address: `ipconfig`
- Check backend server is running
- Try: `curl http://YOUR_IP:3000/health`

### App shows "Offline"?
- Check `.env` has correct IP
- Restart Flutter app
- Check backend terminal for errors

### Sensor not working?
- See `PIN_CONNECTIONS.md` for wiring diagrams
- Test each component individually

---

## 📂 **Project Structure**

```
c:\smart_pendant_app\
│
├── 📄 START_HERE.md                    ← You are here!
├── 📄 SETUP_CHECKLIST.md               ← Step-by-step checklist
├── 📄 INTEGRATION_GUIDE.md             ← Detailed integration guide
├── 📄 PIN_CONNECTIONS.md               ← Hardware wiring reference
│
├── 🤖 arduino\
│   └── smart_pendant_wifi\
│       └── smart_pendant_wifi.ino      ← Arduino firmware (WiFi-based)
│
├── 🖥️ backend\
│   ├── server.js                       ← Node.js backend (relay server)
│   ├── test_server.js                  ← Backend test script
│   └── package.json                    ← Dependencies
│
├── 📱 lib\                              ← Flutter app source code
│   ├── main.dart
│   ├── models\
│   ├── providers\
│   ├── screens\
│   └── services\
│       ├── api_client.dart             ← HTTP API calls
│       └── websocket_service.dart      ← Real-time updates
│
├── 🔧 .env                              ← Configuration (edit this!)
├── 🔧 get_ip.ps1                        ← IP address finder script
└── 📄 pubspec.yaml                      ← Flutter dependencies
```

---

## 🎯 **Your Current Goal**

You want to:
1. ✅ Send live telemetry from Arduino
2. ✅ Receive it in your Flutter app
3. ✅ See location, activity, and sensor data in real-time
4. ✅ Test panic button functionality

**Approach:**
- Use **WiFi** instead of SIM7600E (since SIM has registration issues)
- Arduino → Backend Server → Flutter App
- All running on your local network

---

## 💡 **Tips**

- Open **3 terminal windows**:
  1. Backend server (`npm start`)
  2. Arduino Serial Monitor (115200 baud)
  3. Flutter app (`flutter run`)

- Keep all 3 running simultaneously to see data flow

- Use `SETUP_CHECKLIST.md` to track progress systematically

---

## 🆘 **Need More Help?**

1. Check Arduino Serial Monitor for error messages
2. Check backend terminal for connection logs
3. See `INTEGRATION_GUIDE.md` troubleshooting section
4. Verify wiring with `PIN_CONNECTIONS.md`

---

## 📊 **System Architecture**

```
┌──────────────────────────────────────────────────┐
│  Arduino Nano ESP32 + Sensors                    │
│  • ADXL345 (motion)                              │
│  • GPS L80 (location)                            │
│  • Panic button                                  │
│  • Speaker (alerts)                              │
└─────────────┬────────────────────────────────────┘
              │ WiFi
              │ HTTP POST /api/telemetry
              ↓
┌──────────────────────────────────────────────────┐
│  Backend Server (Node.js on Laptop)             │
│  • Receives telemetry from Arduino               │
│  • Stores latest device state                    │
│  • WebSocket broadcast to Flutter app            │
└─────────────┬────────────────────────────────────┘
              │ WebSocket
              │ Real-time updates
              ↓
┌──────────────────────────────────────────────────┐
│  Flutter Mobile App (Android Emulator)          │
│  • Map with live location                        │
│  • Activity tracking (IDLE/WALK/RUN)             │
│  • Battery & signal status                       │
│  • Panic alerts                                  │
└──────────────────────────────────────────────────┘
```

---

## 🎉 **Let's Go!**

**Recommended Path:**

1. Open `SETUP_CHECKLIST.md` in VS Code
2. Follow each step carefully
3. Mark checkboxes as you complete them
4. Refer to `INTEGRATION_GUIDE.md` if you get stuck

**OR if you want to dive right in:**

```powershell
# Terminal 1: Start backend
cd c:\smart_pendant_app\backend
npm install && npm start

# Terminal 2: Run Flutter app
cd c:\smart_pendant_app
flutter run -d emulator-5554
```

Then configure and upload Arduino code!

---

**📍 Current Status of Your Project:**

✅ Complete Flutter app with 7 screens
✅ Mock data working
✅ Hardware components tested individually
⏳ **Next:** Connect Arduino to app (you're here!)

**🚀 Let's make it happen!**

---

## 📞 Questions?

If you get stuck:
1. Check the Serial Monitor (Arduino)
2. Check backend logs (Node.js terminal)
3. Check Flutter logs (`flutter logs`)
4. Take a screenshot and describe the issue

**Good luck! You've got this! 💪**
