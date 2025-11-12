# 🔊 Audio Playback Fix - Arduino Not Receiving Audio

## Problem
The Flutter app successfully sends audio to the backend server, but the Arduino ESP32 is not receiving it. The backend shows:
```
"Audio received but Arduino is offline"
"error": "timeout of 10000ms exceeded"
```

## Root Cause
The backend server is configured with the **wrong Arduino IP address**. It's trying to send audio to `192.168.0.XXX` but the Arduino is at a different IP.

---

## 🚀 Quick Fix (3 Steps)

### Step 1: Find Arduino's IP Address

**Option A: Check Arduino Serial Monitor** (Fastest)
1. Open Arduino IDE
2. Upload the code to Arduino ESP32
3. Open Serial Monitor (115200 baud)
4. Look for this output:
   ```
   ✅ Connected to WiFi
   📡 IP Address: 192.168.0.XXX
   ```
5. Write down the IP address (e.g., `192.168.0.145`)

**Option B: Run PowerShell Scanner** (Automatic)
1. Open PowerShell in `c:\smart_pendant_app`
2. Run: `.\find_arduino.ps1`
3. Wait 1-2 minutes for network scan
4. It will show the Arduino IP if found

---

### Step 2: Update Backend Server

Edit `backend/server.js` line **266**:

**Before:**
```javascript
const arduinoIp = process.env.ARDUINO_IP || '192.168.0.XXX'; // ⚠️ UPDATE THIS
```

**After (example with IP 192.168.0.145):**
```javascript
const arduinoIp = process.env.ARDUINO_IP || '192.168.0.145'; // ✅ Your Arduino IP
```

---

### Step 3: Restart Backend Server

1. Stop the current backend server (Ctrl+C in PowerShell)
2. Restart it:
   ```powershell
   cd backend
   node server.js
   ```
3. You should see:
   ```
   🚀 Smart Pendant Backend Server Running
   📡 HTTP API:      http://192.168.0.113:3000
   ```

---

## ✅ Testing

1. **Record audio in Flutter app**
2. **Send to Arduino** (tap the recording)
3. **Check backend logs** - should show:
   ```
   🎵 Audio recording received (XXXXX bytes base64)
   📤 Forwarding audio to Arduino at http://192.168.0.145/audio
   ✅ Audio successfully sent to Arduino
   ```
4. **Check Arduino Serial Monitor** - should show:
   ```
   🎵 Received audio POST request
   📦 Body size: XXXX bytes
   📥 Base64 audio length: XXXX
   🔊 Playing audio (XXXX samples at 8000 Hz)
   ✅ Audio playback started on D7
   ```
5. **Listen to speaker** - should hear your recorded audio!

---

## 🔧 Alternative: Use Environment Variable

Instead of hardcoding the IP in `server.js`, you can set it as an environment variable:

**PowerShell:**
```powershell
$env:ARDUINO_IP = "192.168.0.145"
cd backend
node server.js
```

**Windows Command Prompt:**
```cmd
set ARDUINO_IP=192.168.0.145
cd backend
node server.js
```

This way you don't need to edit the code every time the Arduino IP changes.

---

## 📋 Checklist

- [ ] Arduino is powered on
- [ ] Arduino is connected to WiFi: `ZTE_Callie`
- [ ] Found Arduino IP address from Serial Monitor or scanner
- [ ] Updated `backend/server.js` with correct Arduino IP
- [ ] Restarted backend server
- [ ] Tested audio playback from Flutter app
- [ ] Audio plays on speaker connected to D7

---

## 🐛 Troubleshooting

### Arduino Not Connecting to WiFi
- Check WiFi credentials in `arduino/smart_pendant_wifi/smart_pendant_wifi.ino` lines 23-24
- Make sure router is broadcasting SSID: `ZTE_Callie`
- Check Arduino Serial Monitor for connection status

### Backend Still Shows "Arduino is offline"
- Verify Arduino IP is correct (check Serial Monitor)
- Make sure Arduino web server is running (Serial Monitor should show "Web server started")
- Try accessing Arduino web server directly in browser: `http://192.168.0.XXX/`
- Check firewall isn't blocking port 80

### Audio Playback Issues
- Make sure speaker is connected to D7 and GND
- Check Arduino Serial Monitor for audio playback logs
- Verify audio format is WAV (16-bit PCM, 8kHz) - Flutter recording uses this format
- Try increasing volume (speaker might be too quiet)

---

## 📝 Summary

**The Fix:**
1. Find Arduino IP: Check Serial Monitor or run `find_arduino.ps1`
2. Update `backend/server.js` line 266 with correct IP
3. Restart backend server
4. Test audio playback from Flutter app

**Expected Flow:**
```
Flutter App → Backend Server → Arduino ESP32 → Speaker (D7)
   (HTTP)         (HTTP)           (PWM Audio)
```

**Current Status:**
- ✅ Flutter app recording audio correctly
- ✅ Backend server receiving audio
- ❌ Arduino not receiving audio (wrong IP)
- ❌ Speaker not playing audio

After the fix, all steps should be ✅ and audio will play on the speaker!
