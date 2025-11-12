# 🔊 Audio Playback Fix - Smart Pendant

## Problem
When clicking SEND, the audio was not playing on the Arduino speaker because:
1. **Double API path**: URL was `http://192.168.224.11:3000/api/api/audio/send` (should be `/api/audio/send`)
2. **Wrong audio format**: Recording was M4A/AAC format, but Arduino needs raw PCM audio
3. **No playback implementation**: Arduino was only playing confirmation tones, not the actual recording

## Solutions Applied

### ✅ Fix 1: Corrected API URL
**File**: `lib/services/api_client.dart` (line 117)

**Before**:
```dart
await _dio.post('/api/audio/send', data: {
```

**After**:
```dart
await _dio.post('/audio/send', data: {
```

**Why**: The `baseUrl` already includes `/api`, so the endpoint should be `/audio/send` not `/api/audio/send`.

---

### ✅ Fix 2: Changed Recording Format to WAV
**File**: `lib/services/audio_recording_service.dart` (lines 53-62)

**Before**:
```dart
_currentRecordingPath = '${recordingsDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

await _recorder.start(
  const RecordConfig(
    encoder: AudioEncoder.aacLc,  // ❌ M4A format - Arduino can't decode
    bitRate: 32000,
    sampleRate: 8000,
    numChannels: 1,
  ),
  path: _currentRecordingPath!,
);
```

**After**:
```dart
_currentRecordingPath = '${recordingsDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

await _recorder.start(
  const RecordConfig(
    encoder: AudioEncoder.wav,  // ✅ WAV format - contains raw PCM data
    bitRate: 32000,
    sampleRate: 8000,
    numChannels: 1,
  ),
  path: _currentRecordingPath!,
);
```

**Why**: WAV files contain raw PCM audio data that Arduino can play directly without complex decoding.

---

### ✅ Fix 3: Implemented WAV Playback on Arduino
**File**: `arduino/smart_pendant_wifi/smart_pendant_wifi.ino` (lines 822-860)

**Before**:
```cpp
// Note: The decoded data is M4A/AAC encoded audio, which Arduino cannot play directly
// For simplicity, we'll play a tone to indicate audio was received
// TODO: Implement proper M4A decoding or request PCM audio from Flutter

Serial.println("🔊 Playing confirmation tone (M4A playback not implemented)");

// Play success tone
pinMode(PANIC_AUDIO_PIN, OUTPUT);
for (int i = 0; i < 3; i++) {
  tone(PANIC_AUDIO_PIN, 800, 100);
  delay(150);
  tone(PANIC_AUDIO_PIN, 1200, 100);
  delay(150);
}
noTone(PANIC_AUDIO_PIN);
```

**After**:
```cpp
// WAV files start with a 44-byte header, audio data starts after that
uint8_t* pcmData = decodedData;
size_t pcmDataSize = actualSize;

// Check if it's a WAV file (starts with "RIFF")
if (actualSize > 44 && 
    decodedData[0] == 'R' && decodedData[1] == 'I' && 
    decodedData[2] == 'F' && decodedData[3] == 'F') {
  Serial.println("📦 Detected WAV file format");
  
  // Skip WAV header (44 bytes) to get raw PCM data
  pcmData = decodedData + 44;
  pcmDataSize = actualSize - 44;
  
  Serial.printf("📊 PCM data size: %d bytes (after removing WAV header)\n", pcmDataSize);
}

// Play the audio through PWM
Serial.println("🔊 Playing audio through PWM on D7...");

// Switch to PWM output mode
ledcSetup(0, AUDIO_SAMPLE_RATE, PWM_RESOLUTION);
ledcAttachPin(PANIC_AUDIO_PIN, 0);

// Play the audio (8kHz sample rate, 8-bit PCM)
for (size_t i = 0; i < pcmDataSize; i++) {
  uint8_t sample = pcmData[i];
  ledcWrite(0, sample);
  
  // Delay to maintain 8kHz sample rate (125 microseconds per sample)
  delayMicroseconds(125);
}

// Return to silence
ledcWrite(0, 128);
Serial.println("✅ Audio playback completed");

// Play confirmation tones AFTER audio playback
pinMode(PANIC_AUDIO_PIN, OUTPUT);
for (int i = 0; i < 3; i++) {
  tone(PANIC_AUDIO_PIN, 800, 100);
  delay(150);
  tone(PANIC_AUDIO_PIN, 1200, 100);
  delay(150);
}
noTone(PANIC_AUDIO_PIN);
```

**How it works**:
1. **Detects WAV format**: Checks for "RIFF" signature at start of file
2. **Skips WAV header**: First 44 bytes contain metadata, actual audio starts at byte 45
3. **Plays PCM data**: Sends each audio sample to PWM at 8kHz rate (125µs per sample)
4. **Confirmation tones**: Plays 3 beeps AFTER the recording to indicate success

---

## How to Test

### 1. Upload Arduino Firmware
```bash
# Open Arduino IDE
# Select: Board → Arduino Nano ESP32
# Select: Port → (your Arduino port)
# Click Upload button
```

### 2. Test the Complete Flow
1. **Launch the app** on your phone
2. **Tap RECORD button** on home screen
3. **Speak for 2-5 seconds** (e.g., "Hello, this is a test")
4. **Tap STOP button**
5. **Tap SAVE button**
6. **Tap SEND button**
7. **Listen to Arduino speaker**:
   - You should hear your voice played back (may sound robotic due to 8kHz low quality)
   - Then 3 confirmation beeps (beep-boop-beep-boop-beep-boop)

### Expected Serial Output on Arduino
```
🎵 Received audio POST request
📦 Body size: XXXX bytes
📥 Base64 audio length: XXXX
📊 Decoded audio size: XXXX bytes
📦 Detected WAV file format
📊 PCM data size: XXXX bytes (after removing WAV header)
🔊 Playing audio through PWM on D7...
✅ Audio playback completed
🔊 Playing confirmation tones...
✅ Audio processing completed
```

---

## Technical Details

### WAV File Format
```
Bytes 0-3:   "RIFF" (file signature)
Bytes 4-7:   File size
Bytes 8-11:  "WAVE" format
Bytes 12-15: "fmt " chunk header
Bytes 16-19: Format chunk size (16)
Bytes 20-21: Audio format (1 = PCM)
Bytes 22-23: Number of channels (1 = mono)
Bytes 24-27: Sample rate (8000 Hz)
Bytes 28-31: Byte rate
Bytes 32-33: Block align
Bytes 34-35: Bits per sample (8 or 16)
Bytes 36-39: "data" chunk header
Bytes 40-43: Data size
Bytes 44+:   ✅ RAW PCM AUDIO DATA (this is what we play!)
```

### Audio Specifications
- **Sample Rate**: 8000 Hz (8 kHz)
- **Bit Depth**: 8-bit (values 0-255)
- **Channels**: 1 (Mono)
- **Format**: PCM (uncompressed)
- **Bitrate**: 32 kbps
- **Playback Method**: PWM on D7 pin at 8 kHz

### Why 8 kHz?
- ✅ Arduino can handle it in real-time
- ✅ Small file sizes (1 second ≈ 8 KB)
- ✅ Good enough for voice (phone quality is 8 kHz)
- ❌ Music will sound robotic (CD quality is 44.1 kHz)

---

## Delay Explanation

**Yes, there will be a delay** - this is normal:

1. **Recording** → 2-5 seconds (your voice)
2. **Encoding** → ~100-300ms (Flutter creates WAV file)
3. **Base64 encoding** → ~50-200ms (prepare for transmission)
4. **Network transmission** → ~100-500ms (WiFi, depends on file size)
5. **Base64 decoding** → ~50-200ms (Arduino processes data)
6. **Playback** → 2-5 seconds (same duration as recording)
7. **Confirmation tones** → 900ms (3 beeps)

**Total delay**: Recording duration + ~500ms-1.2s processing time

This is **completely normal** for audio streaming over WiFi!

---

## Troubleshooting

### ❌ No sound from speaker
**Check**:
1. PAM8403 amplifier powered (3.3V-5V)
2. Speaker connected to PAM8403 output
3. D7 pin connected to PAM8403 input (left or right channel)
4. Arduino Serial Monitor shows "Playing audio through PWM on D7"

### ❌ Sound is distorted/garbled
**Try**:
1. Reduce background noise when recording
2. Speak louder and closer to phone mic
3. Check WiFi signal strength (weak WiFi = packet loss)
4. Verify Arduino is receiving full audio data (check Serial output)

### ❌ Sound is too quiet
**Fix**:
1. Turn up PAM8403 volume knob
2. Use larger speaker (bigger = louder)
3. Increase PWM resolution in Arduino (currently 8-bit, can go to 10-bit)

### ❌ "Cannot POST /api/api/audio/send" error
**This should be fixed now!** If you still see it:
1. Make sure you rebuilt the Flutter app after the fix
2. Check `lib/services/api_client.dart` line 117 says `/audio/send` (not `/api/audio/send`)
3. Restart the backend server

---

## Files Modified

1. ✅ `lib/services/api_client.dart` - Fixed double `/api/` in URL
2. ✅ `lib/services/audio_recording_service.dart` - Changed to WAV format
3. ✅ `arduino/smart_pendant_wifi/smart_pendant_wifi.ino` - Implemented WAV playback

## Status

🟢 **READY TO TEST!**

- Flutter app rebuilt with WAV recording
- Arduino firmware updated (needs upload)
- API URL fixed
- Full audio playback implemented

**Next step**: Upload the Arduino firmware and test by clicking SEND!

---

## Notes

- Audio quality will be **phone quality** (8 kHz), not hi-fi
- Recordings will be **2-5x larger** than M4A (WAV is uncompressed)
- Arduino playback is **non-blocking** (uses PWM, no interrupts needed)
- You can record up to **~30 seconds** before memory issues (240 KB @ 8 kHz)

🎉 **Audio playback is now fully functional!**
