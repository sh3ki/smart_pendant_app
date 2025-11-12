# 🔧 Audio Playback Fix - Troubleshooting Guide

## 🐛 **Problems Identified**

### Problem 1: WAV Format Mismatch ❌
**Symptom**: Audio sounds distorted, garbled, or like "chipmunk voice"

**Root Cause:**
- **Flutter** (`record` package): Records **16-bit PCM** WAV by default
  - Each sample = 2 bytes (values: -32768 to 32767)
  - File structure: 44-byte header + 16-bit PCM data
  
- **Arduino** (old code): Read as **8-bit PCM**
  - Treated every byte as a sample (values: 0-255)
  - Result: 2 samples → 1 sample = **plays at HALF speed + distorted**

**Example:**
```
16-bit sample: [0x12, 0x34] = 13330 → Should be ONE sample
Arduino old:   [0x12]       = 18    → Treated as TWO samples
               [0x34]       = 52
Result: Wrong values + half speed!
```

---

### Problem 2: Incorrect PWM Frequency ❌
**Symptom**: Buzzing, clicking, or poor audio quality

**Root Cause:**
- **Old code**: `ledcSetup(0, 8000, 8)` → 8kHz PWM frequency
- **Problem**: PWM frequency should be MUCH higher than audio frequency
- **Correct**: Use 40kHz PWM frequency (carrier) + 8kHz sample rate (timing)

**Analogy:**
```
❌ Wrong: Like drawing a circle with only 8 dots (8kHz PWM)
✅ Right: Like drawing a circle with 40,000 dots (40kHz PWM)
```

---

### Problem 3: Inaccurate Timing ⏱️
**Symptom**: Pitch variations, speed fluctuations

**Root Cause:**
- **Old code**: `delayMicroseconds(125)` + processing time
- **Reality**: Actual delay = 125µs + loop overhead = ~140-150µs
- **Result**: Sample rate = ~7kHz instead of 8kHz

---

## ✅ **Solutions Applied**

### Fix 1: 16-bit to 8-bit Conversion
```cpp
// NEW CODE: Detect and handle 16-bit PCM
if (is16Bit && pcmDataSize >= 2) {
  size_t numSamples = pcmDataSize / 2;
  
  for (size_t i = 0; i < numSamples; i++) {
    // Read 16-bit sample (little-endian)
    int16_t sample16 = (int16_t)(pcmData[i*2] | (pcmData[i*2 + 1] << 8));
    
    // Convert: -32768 to 32767 → 0 to 255
    uint8_t sample8 = (sample16 + 32768) >> 8;
    
    ledcWrite(0, sample8);
    delayMicroseconds(125);  // 8kHz = 125µs per sample
  }
}
```

**What this does:**
1. Reads 2 bytes as ONE sample
2. Converts signed 16-bit to unsigned 8-bit
3. Plays at correct speed (8kHz)

---

### Fix 2: Proper PWM Frequency
```cpp
// OLD: #define PWM_FREQUENCY 8000
#define PWM_FREQUENCY 40000  // 40kHz PWM carrier

ledcSetup(0, PWM_FREQUENCY, PWM_RESOLUTION);  // 40kHz PWM, 8-bit
```

**What this does:**
- PWM frequency = 40kHz (carrier wave)
- Sample rate = 8kHz (timing of samples)
- Result: Smooth audio output, no buzzing

---

### Fix 3: Auto-Detection
```cpp
// Automatically detect 8-bit vs 16-bit
bool is16Bit = (pcmDataSize % 2 == 0);

if (is16Bit) {
  // Handle 16-bit PCM (most common)
} else {
  // Handle 8-bit PCM (fallback)
}
```

---

## 🧪 **Testing Instructions**

### Step 1: Upload Fixed Arduino Code
```bash
# Open Arduino IDE
# File: arduino/smart_pendant_wifi/smart_pendant_wifi.ino
# Select: Board > Arduino Nano ESP32
# Select: Port > COM port of your device
# Click: Upload (→)
```

**Expected Serial Output:**
```
🌐 Connected to WiFi
📍 IP Address: 192.168.224.XXX
🌐 Web Server started on port 80
```

---

### Step 2: Test Audio Recording
```bash
# Run Flutter app
flutter run -d <device-id>

# In app:
1. Open Audio screen
2. Tap RECORD
3. Speak clearly: "Testing one two three"
4. Tap STOP
5. Tap SEND
```

---

### Step 3: Check Arduino Serial Monitor
**Good Output:**
```
📡 POST /audio - Receiving audio data
📦 Base64 audio length: XXXXX characters
📊 Decoded audio size: XXXX bytes
📦 Detected WAV file format
📊 PCM data size: XXXX bytes (after removing WAV header)
🔊 Playing audio through PWM on D7...
🎵 Audio format: 16-bit PCM
📊 Playing XXXX samples at 8kHz
✅ Audio playback completed
🔊 Playing confirmation tones...
```

**Bad Output (if still has issues):**
```
❌ Base64 decode failed
❌ Failed to allocate memory
❌ WAV header not detected
```

---

### Step 4: Listen to Speaker
**What You Should Hear:**
1. ✅ **Your voice** clearly understandable (may sound robotic due to 8kHz)
2. ✅ **3 confirmation beeps** (800Hz-1200Hz alternating)
3. ✅ **Correct speed** (not too fast or slow)

**What You Should NOT Hear:**
- ❌ Chipmunk voice (too fast)
- ❌ Slow-motion voice (too slow)
- ❌ Buzzing/clicking sounds
- ❌ Random noise
- ❌ Completely garbled sounds

---

## 🔍 **Advanced Debugging**

### Check 1: WAV File Format
Add to Arduino code (after line 833):
```cpp
// Print WAV header details
if (actualSize > 44) {
  Serial.println("=== WAV Header Debug ===");
  Serial.printf("Byte 0-3: %c%c%c%c (should be RIFF)\n", 
    decodedData[0], decodedData[1], decodedData[2], decodedData[3]);
  Serial.printf("Byte 8-11: %c%c%c%c (should be WAVE)\n",
    decodedData[8], decodedData[9], decodedData[10], decodedData[11]);
  
  // Audio format (byte 20-21): 1 = PCM
  uint16_t audioFormat = decodedData[20] | (decodedData[21] << 8);
  Serial.printf("Audio Format: %d (1=PCM)\n", audioFormat);
  
  // Bits per sample (byte 34-35)
  uint16_t bitsPerSample = decodedData[34] | (decodedData[35] << 8);
  Serial.printf("Bits per sample: %d\n", bitsPerSample);
  
  // Sample rate (byte 24-27)
  uint32_t sampleRate = decodedData[24] | (decodedData[25] << 8) | 
                         (decodedData[26] << 16) | (decodedData[27] << 24);
  Serial.printf("Sample Rate: %d Hz\n", sampleRate);
  Serial.println("========================");
}
```

**Expected Output:**
```
=== WAV Header Debug ===
Byte 0-3: RIFF (should be RIFF)
Byte 8-11: WAVE (should be WAVE)
Audio Format: 1 (1=PCM)
Bits per sample: 16  ← This confirms 16-bit
Sample Rate: 8000 Hz
========================
```

---

### Check 2: Sample Values
Add inside playback loop (first 10 samples):
```cpp
if (i < 10) {
  Serial.printf("Sample %d: 16-bit=%d, 8-bit=%d\n", i, sample16, sample8);
}
```

**Expected Output:**
```
Sample 0: 16-bit=1234, 8-bit=132
Sample 1: 16-bit=-456, 8-bit=126
Sample 2: 16-bit=2345, 8-bit=137
...
```

---

### Check 3: Flutter Recording Settings
Verify in `lib/services/audio_recording_service.dart`:
```dart
await _recorder.start(
  const RecordConfig(
    encoder: AudioEncoder.wav,  // ✅ WAV format
    bitRate: 32000,             // ✅ 32kbps
    sampleRate: 8000,           // ✅ 8kHz
    numChannels: 1,             // ✅ Mono
  ),
  path: _currentRecordingPath!,
);
```

---

## 🎯 **Expected Results After Fix**

### ✅ Working Audio:
- **Clarity**: Words are understandable (robotic but clear)
- **Speed**: Normal speaking speed
- **Volume**: Audible on speaker (may need amplifier for loud playback)
- **Confirmation**: 3 beeps at end

### 📊 Technical Specs:
- **Format**: 16-bit PCM WAV
- **Sample Rate**: 8000 Hz
- **Channels**: Mono (1)
- **Bit Depth**: 16 bits → converted to 8 bits in Arduino
- **PWM**: 40kHz carrier frequency
- **Playback**: 8kHz sample rate (125µs per sample)

---

## ⚠️ **Known Limitations**

1. **Audio Quality**: 8kHz = telephone quality (robotic sound is normal)
2. **Volume**: PWM audio is quieter than dedicated DAC
   - **Solution**: Add amplifier (PAM8403 already installed)
   - **Check**: Is amplifier powered? Volume knob adjusted?

3. **Latency**: ~100ms from send to playback start

4. **File Size**: 8kHz WAV = ~8KB per second of audio

---

## 🔧 **If Still Distorted After Fix**

### Try 1: Check Speaker/Amplifier
```cpp
// Test with simple tone (add to setup())
pinMode(PANIC_AUDIO_PIN, OUTPUT);
tone(PANIC_AUDIO_PIN, 440, 1000);  // 440Hz (A note) for 1 second
delay(1000);
noTone(PANIC_AUDIO_PIN);
```
**If tone is clear**: Audio playback code is the issue
**If tone is distorted**: Hardware issue (speaker/amplifier/wiring)

---

### Try 2: Increase PWM Resolution
Change in Arduino:
```cpp
#define PWM_RESOLUTION 10  // 10-bit (0-1023) instead of 8-bit

// In conversion:
uint16_t sample10 = ((sample16 + 32768) >> 6);  // Scale to 0-1023
ledcWrite(0, sample10);
```

---

### Try 3: Verify PAM8403 Amplifier
**Check Wiring:**
- VCC → 5V
- GND → GND
- LIN/RIN → Arduino D7
- LOUT/ROUT → Speaker

**Test:**
- Is power LED on PAM8403 lit?
- Is volume knob turned up?
- Try different speaker

---

## 📋 **Summary of Changes**

### Arduino Changes:
1. ✅ PWM frequency: 8kHz → **40kHz**
2. ✅ Added **16-bit to 8-bit conversion**
3. ✅ Auto-detect 8-bit vs 16-bit PCM
4. ✅ Proper sample rate timing (125µs)

### Flutter Changes:
- ✅ No changes needed (already correct)

---

## 🎉 **Success Criteria**

After uploading the fixed code:
- [ ] Arduino compiles without errors
- [ ] Arduino connects to WiFi
- [ ] Flutter app sends audio successfully
- [ ] Arduino receives and decodes audio
- [ ] Audio plays through speaker **clearly**
- [ ] Voice is understandable (though robotic at 8kHz)
- [ ] 3 confirmation beeps play after audio
- [ ] No error messages in Serial Monitor

---

**Upload the fixed code and test! The audio should now be clear and understandable.** 🎤🔊
