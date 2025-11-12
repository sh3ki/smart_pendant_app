# 🚀 AUDIO RECORDING QUICK START

## ⚡ Fastest Way to Test (3 Steps)

### **Step 1: Start Backend Server**
```powershell
cd backend
npm install  # Only first time
node server.js
```
**Look for**: `🚀 Smart Pendant Backend Server Running`

---

### **Step 2: Run Flutter App**
```powershell
# In new terminal
flutter pub get  # Only first time
flutter run
```
**Look for**: App opens on emulator/device

---

### **Step 3: Test Recording**
1. Navigate to **Audio** screen (bottom nav bar)
2. Tap **RECORD** button (turns red)
3. Wait 3-5 seconds
4. Tap **STOP** button
5. See **REPLAY / CANCEL / SAVE / SEND** buttons

✅ **Recording works!**

---

## 🧪 Full Feature Test (5 Minutes)

### **Test 1: Record & Replay**
1. Tap **RECORD** → Wait 5 seconds → Tap **STOP**
2. Tap **REPLAY** → Audio plays
3. ✅ **Pass**: Hear your voice

### **Test 2: Save & List**
1. Record audio
2. Tap **SAVE**
3. See green toast: "Recording saved!"
4. Tap list icon (top-right, shows badge "1")
5. ✅ **Pass**: Recording appears in list

### **Test 3: Play from List**
1. In recordings list, tap **Play** button (▶️)
2. ✅ **Pass**: Audio plays

### **Test 4: Send to Arduino**
1. In recordings list, tap **Send** button (📤)
2. See green toast: "Recording sent to Arduino!"
3. Check backend terminal: `🎵 Audio recording received`
4. ✅ **Pass**: Backend receives audio

### **Test 5: Delete**
1. In recordings list, tap **Delete** button (🗑️)
2. Confirm deletion
3. ✅ **Pass**: Recording removed from list

---

## 🤖 Arduino Setup (For Full End-to-End Test)

### **Requirements**
- Arduino Nano ESP32
- PAM8403 audio amplifier on D7
- 8Ω speaker
- WiFi connection (same network as computer)

### **Steps**
1. Open Arduino IDE
2. Install libraries: `WebServer`, `ArduinoJson`, `HTTPClient`
3. Open `arduino/smart_pendant_wifi/smart_pendant_wifi.ino`
4. Update WiFi credentials (line 19-20):
   ```cpp
   const char* WIFI_SSID = "YourWiFiName";
   const char* WIFI_PASSWORD = "YourPassword";
   ```
5. Upload to Arduino
6. Open Serial Monitor (115200 baud)
7. **Copy Arduino IP address** (shows: `http://192.168.X.X/audio`)
8. Edit `backend/server.js` line ~218:
   ```javascript
   const arduinoIp = '192.168.X.X'; // Paste Arduino IP
   ```
9. Restart backend server
10. Send audio from Flutter app
11. **Listen**: Arduino plays 3-beep confirmation tone!

---

## 📱 UI Elements Guide

### **Audio Screen**
```
┌─────────────────────────────────┐
│ Audio Recording      [List 📋] │ ← Badge shows count
├─────────────────────────────────┤
│                                 │
│        ⭕ 🎤                     │ ← Red when recording
│                                 │
│        00:23                    │ ← Timer
│     Recording...                │
│                                 │
│   [●  STOP  ]                   │ ← Red button
│                                 │
└─────────────────────────────────┘

After recording:
┌─────────────────────────────────┐
│        ⭕ 🎤                     │ ← Blue circle
│        00:05                    │
│     Ready to replay             │
│                                 │
│   [▶  REPLAY  ]                 │ ← Blue button
│                                 │
│ [❌ CANCEL] [💾 SAVE] [📤 SEND]│
└─────────────────────────────────┘
```

### **Recordings List**
```
┌─────────────────────────────────┐
│ Saved Recordings          [ℹ️]  │
├─────────────────────────────────┤
│ 🎤 Recording 5 min ago          │
│    ⏱️ 00:05  📅 5 min ago       │
│    ✅ Sent to Arduino           │ ← Green checkmark
│           [▶️] [🗑️]             │ ← Play/Delete
├─────────────────────────────────┤
│ 🎤 Recording Yesterday          │
│    ⏱️ 00:12  📅 Yesterday       │
│           [▶️] [📤] [🗑️]        │ ← Play/Send/Delete
└─────────────────────────────────┘
```

---

## ⚠️ Common Issues

### **Issue: App crashes on record**
**Cause**: Microphone permission not granted
**Fix**: Go to phone Settings → Apps → Smart Pendant → Permissions → Microphone → Allow

### **Issue: "Failed to send"**
**Cause**: Backend not running
**Fix**: 
```powershell
cd backend
node server.js
```

### **Issue: Backend says "Arduino is offline"**
**Cause**: Arduino IP not configured or Arduino not connected
**Fix**: 
1. Check Arduino Serial Monitor for IP
2. Update `backend/server.js` with correct IP
3. Restart backend

### **Issue: No sound from Arduino**
**Cause**: D7 not connected to PAM8403 or speaker
**Fix**: 
- Arduino D7 → PAM8403 L/R Input
- PAM8403 5V → LM2596 5V output
- PAM8403 GND → Arduino GND
- PAM8403 Output → 8Ω Speaker

---

## 📊 Success Indicators

### **Flutter App**
- ✅ Red pulsing circle during recording
- ✅ Timer counts up (00:01, 00:02, ...)
- ✅ Replay plays audio through phone speaker
- ✅ Green toasts show "Recording saved!"
- ✅ Orange toasts show "Recording sent to Arduino!"
- ✅ List shows recordings with timestamps
- ✅ Badge counter updates

### **Backend Terminal**
```
🎵 Audio recording received (12345 bytes base64)
📅 Timestamp: 2025-10-15T12:34:56.789Z
📤 Forwarding audio to Arduino at http://192.168.1.100/audio
✅ Audio successfully sent to Arduino
```

### **Arduino Serial Monitor**
```
🎵 Received audio POST request
📦 Body size: 15432 bytes
📥 Base64 audio length: 12345
📊 Decoded audio size: 9256 bytes
🔊 Playing confirmation tone (M4A playback not implemented)
✅ Audio received successfully
```

### **Physical Arduino**
- 🔊 **Hear 3 beeps**: 800Hz → 1200Hz → 800Hz → 1200Hz → 800Hz → 1200Hz

---

## 🎯 What Works Right Now

✅ **Record** - Tap button, timer starts, red indicator
✅ **Stop** - Recording saved to memory
✅ **Replay** - Play audio through phone speaker
✅ **Save** - Persist to Hive database
✅ **List** - View all saved recordings
✅ **Send** - Transmit to backend → forward to Arduino
✅ **Delete** - Remove recording + file
✅ **Playback Controls** - Play/stop from list
✅ **Sent Status** - Green checkmark for sent recordings
✅ **Error Handling** - Permission checks, network errors
✅ **Arduino Reception** - Receives audio, plays confirmation tone

---

## 🔮 What Doesn't Work Yet

❌ **Arduino Full Playback** - Currently plays confirmation tone only
   - **Why**: M4A/AAC decoding requires external decoder chip
   - **Future**: Add VS1053 decoder or switch to PCM format

❌ **Offline Caching** - Audio not cached if Arduino offline
   - **Why**: Not implemented in backend yet
   - **Future**: Store in backend DB, retry when Arduino reconnects

---

## 📞 Support

**Check Documentation:**
- [AUDIO_RECORDING_COMPLETE.md](./AUDIO_RECORDING_COMPLETE.md) - Full technical docs
- [AUDIO_RECORDING_IMPLEMENTATION_PLAN.md](./AUDIO_RECORDING_IMPLEMENTATION_PLAN.md) - Architecture

**Check Logs:**
- **Flutter**: Check app console for errors
- **Backend**: Check `node server.js` terminal
- **Arduino**: Check Serial Monitor (115200 baud)

---

**Last Updated**: October 15, 2025
**Status**: ✅ READY TO TEST
