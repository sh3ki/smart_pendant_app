# Arduino Compilation Fixes

## Issues Fixed

### 1. ❌ `Wire.requestFrom()` Ambiguity
**Error:**
```
call of overloaded 'requestFrom(int, int, bool)' is ambiguous
```

**Fix:**
```cpp
// OLD (ambiguous):
Wire.requestFrom(ADXL345_ADDRESS, 6, true);

// NEW (explicit types):
Wire.requestFrom((uint8_t)ADXL345_ADDRESS, (uint8_t)6, (uint8_t)1);
```

**Reason:** ESP32 Arduino Core 2.0.18 has multiple overloaded versions of `requestFrom()`. Explicit casting resolves ambiguity.

---

### 2. ❌ Base64 Function Names
**Error:**
```
'base64_dec_len' was not declared in this scope
'base64_decode' was not declared in this scope
```

**Fix:**
```cpp
// OLD (incorrect function names):
size_t decodedSize = base64_dec_len(base64Audio, strlen(base64Audio));
int actualSize = base64_decode((char*)decodedData, base64Audio, strlen(base64Audio));

// NEW (correct Arduino base64 library API):
String base64Str = String(base64Audio);
int decodedSize = base64::decodeLength(base64Str);
int actualSize = base64::decode(decodedData, base64Str);
```

**Reason:** Arduino's `base64.h` library uses `base64::decodeLength()` and `base64::decode()`, not C-style function names.

---

## Compilation Status

### Before Fixes:
- ❌ Multiple compilation errors
- ❌ Exit status 1

### After Fixes:
- ✅ Fixed `Wire.requestFrom()` ambiguity with explicit casts
- ✅ Fixed base64 function calls to match Arduino library API
- ✅ Code should now compile successfully

---

## Required Arduino Libraries

Ensure these libraries are installed in Arduino IDE:

1. **Built-in ESP32 Libraries:**
   - `WiFi.h` ✅ (ESP32 core)
   - `WebServer.h` ✅ (ESP32 core)
   - `HTTPClient.h` ✅ (ESP32 core)
   - `Wire.h` ✅ (ESP32 core)

2. **Install via Library Manager:**
   - `ArduinoJson` by Benoit Blanchon (v6.x recommended)
   - `base64` by Arturo Guadalupi (or use ESP32 built-in if available)

---

## Upload Instructions

1. **Open Arduino IDE**
2. **Select Board:**
   - Tools → Board → esp32 → Arduino Nano ESP32
3. **Select Port:**
   - Tools → Port → (your COM port)
4. **Verify Libraries:**
   - Sketch → Include Library → Manage Libraries
   - Search and install: `ArduinoJson`
5. **Upload:**
   - Click Upload button (or Ctrl+U)
6. **Monitor Serial:**
   - Tools → Serial Monitor (115200 baud)
   - Should see: "Smart Pendant with Camera" startup message

---

## Expected Serial Output

```
╔════════════════════════════════════════╗
║  🚀 Smart Pendant with Camera        ║
║     5 FPS Video Streaming            ║
╚════════════════════════════════════════╝

🔍 Scanning I2C bus...
  ✅ Found device at 0x53 (ADXL345)
  Total devices found: 1

🔧 Initializing ADXL345... ✅ OK
📷 Initializing OV7670 camera...
   ⚠️  Camera MUST have 3.3V power (NOT 5V!)
   🔌 Step 1: Hardware power-on sequence
      ✅ RESET released, PWDN disabled
   📌 Step 2: Configuring data/sync pins
   🔄 Step 3: Starting MCLK (10 MHz)
      ✅ MCLK running
   🔍 Step 4: Checking camera output signals
      VS=LOW HS=HIGH PCLK=LOW
      ⚠️  HS/PCLK signals present but VS missing
      ℹ️  Camera may need I2C config to enable VS
   🔍 Step 5: Attempting I2C detection
      Trying addresses: 0x21 0x42 0x43 0x30 0x60 0x61 0x20 0x40 0x41 
      ❌ Not detected on I2C bus
      ⚠️  Attempting FORCED I2C configuration (no ACK)
Camera initialized: NO
📡 GPS Serial initialized
📶 Connecting to WiFi: wifi
..........
✅ WiFi Connected!
📍 IP Address: 192.168.224.XX
🔊 Audio PWM initialized on D7 (8kHz, 8-bit)
🌐 Web Server started on port 80
   Audio endpoint: http://192.168.224.XX/audio

✅ Setup complete! Starting main loop...
```

---

## Testing Audio Reception

1. **Start Backend Server:**
   ```bash
   cd backend
   node server.js
   ```

2. **Run Flutter App:**
   ```bash
   flutter run -d emulator-5554
   ```

3. **Record Audio in App:**
   - Tap "RECORD" button
   - Speak for a few seconds
   - Tap "STOP"
   - Tap "SEND"

4. **Arduino Should:**
   - Receive POST request at `/audio`
   - Decode base64 audio
   - Play 3 confirmation beeps (800Hz → 1200Hz)
   - Print "✅ Audio received successfully"

---

## Notes

- **Camera Status:** OV7670 camera not functional due to defective I2C interface
- **Audio Format:** Flutter records in M4A/AAC format (8kHz mono)
- **Arduino Limitation:** Currently plays confirmation tones only (M4A decoding not implemented)
- **Future Enhancement:** Use PCM audio format for direct playback on Arduino
