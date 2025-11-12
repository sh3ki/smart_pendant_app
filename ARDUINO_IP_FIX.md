# 🔧 Quick Fix: Update Arduino IP Address

## Problem
The backend server can't reach your Arduino because it's using a placeholder IP `192.168.224.XX`.

## Solution Steps

### Step 1: Find Arduino's IP Address

Look at your **Arduino Serial Monitor** output. Near the top when it first starts, you should see:

```
📶 Connecting to WiFi: wifi
.......
✅ WiFi Connected!
📍 IP Address: 192.168.224.XXX  <--- THIS IS WHAT WE NEED!
```

**Write down this IP address!**

If you can't find it, **press the RESET button on the Arduino** and watch the Serial Monitor for the IP address.

---

### Step 2: Update Backend Server

**Option A - Set Environment Variable (Recommended)**

In PowerShell terminal:
```powershell
cd backend
$env:ARDUINO_IP="192.168.224.XXX"  # Replace XXX with your Arduino IP
node server.js
```

**Option B - Edit server.js File**

1. Open `backend/server.js`
2. Find line 230 (around line 230)
3. Change:
   ```javascript
   const arduinoIp = process.env.ARDUINO_IP || '192.168.224.XX';
   ```
   To:
   ```javascript
   const arduinoIp = process.env.ARDUINO_IP || '192.168.224.XXX'; // Your Arduino IP here
   ```
4. Save the file
5. Restart the backend server

---

### Step 3: Restart Backend Server

```powershell
cd backend
node server.js
```

You should see:
```
🚀 Smart Pendant Backend Server Running
📡 Port: 3000
🌐 http://192.168.224.11:3000
```

---

### Step 4: Test Audio Playback

1. Open the Flutter app
2. Tap **RECORD**
3. Speak for 2-5 seconds
4. Tap **STOP**
5. Tap **SAVE**
6. Tap **SEND**
7. **Listen to the Arduino speaker!**

You should hear:
- Your voice (8kHz quality)
- Then 3 confirmation beeps

---

## Arduino Serial Output (Expected)

```
🎵 Received audio POST request
📦 Body size: 33576 bytes
📥 Base64 audio length: 44768
📊 Decoded audio size: 33576 bytes
📦 Detected WAV file format
📊 PCM data size: 33532 bytes (after removing WAV header)
🔊 Playing audio through PWM on D7...
✅ Audio playback completed
🔊 Playing confirmation tones...
✅ Audio processing completed
```

---

## Backend Terminal Output (Expected)

```
🎵 Audio recording received (44768 bytes base64)
📅 Timestamp: 2025-10-15T07:53:23.000Z
📤 Forwarding audio to Arduino at http://192.168.224.XXX/audio
✅ Audio successfully sent to Arduino
   Arduino response: { success: true, message: 'Audio received and played successfully' }
```

---

## Quick Commands Summary

```powershell
# Terminal 1 - Backend Server
cd C:\smart_pendant_app\backend
$env:ARDUINO_IP="192.168.224.XXX"  # Use your actual Arduino IP
node server.js

# Terminal 2 - Flutter App (if needed)
cd C:\smart_pendant_app
flutter run -d 1263040489008311
```

---

## Troubleshooting

### ❌ Still says "Arduino is offline"
- **Check**: Arduino Serial Monitor shows WiFi connected
- **Check**: Arduino IP is correct (ping it from PowerShell: `ping 192.168.224.XXX`)
- **Check**: Arduino and computer on same WiFi network
- **Check**: Backend server restarted after changing IP

### ❌ Arduino receives audio but no sound
- **Check**: PAM8403 powered (3.3V or 5V)
- **Check**: Speaker connected to PAM8403 output
- **Check**: D7 pin connected to PAM8403 input (LIN or RIN)
- **Check**: Volume knob on PAM8403 turned up

### ❌ Sound is garbled/distorted
- **Try**: Record in quieter environment
- **Try**: Speak louder and closer to phone
- **Note**: 8kHz audio = phone quality (will sound robotic for music)

---

🎯 **Once you update the Arduino IP, everything should work!**
