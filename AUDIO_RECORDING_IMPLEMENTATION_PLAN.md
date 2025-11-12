# 🎙️ **AUDIO RECORDING SYSTEM - COMPLETE IMPLEMENTATION PLAN**

## 📋 **Overview**
Replace "Listen/Speak" functionality with a full **Audio Recording System** that allows:
1. ✅ Record audio in the app
2. ✅ Replay recorded audio
3. ✅ Save recordings to a list
4. ✅ Send recordings to Arduino for speaker playback
5. ✅ Cancel/delete recordings

---

## 🏗️ **Architecture**

```
┌─────────────────┐         ┌─────────────────┐         ┌──────────────────┐
│  Flutter App    │         │   Backend       │         │  Arduino Nano    │
│                 │         │   (Node.js)     │         │  ESP32           │
│ ┌─────────────┐ │         │                 │         │                  │
│ │  Record UI  │ │   HTTP  │ /api/audio/send │  HTTP   │ Play via PAM8403 │
│ │  - Record   │ ├────────>│                 ├────────>│ Speaker (D7 pin) │
│ │  - Replay   │ │         │ Forward to      │         │                  │
│ │  - Save     │ │         │ Arduino         │         │ Base64 → PCM     │
│ │  - Send     │ │         │                 │         │ → PWM audio      │
│ └─────────────┘ │         └─────────────────┘         └──────────────────┘
│                 │
│ ┌─────────────┐ │
│ │ Recordings  │ │ (Local Storage - Hive DB)
│ │    List     │ │
│ └─────────────┘ │
└─────────────────┘
```

---

## 📦 **Required Packages**

### Flutter (pubspec.yaml)
```yaml
dependencies:
  # Audio Recording & Playback
  record: ^5.1.0           # Audio recording
  audioplayers: ^6.0.0     # Audio playback (lighter than just_audio)
  path_provider: ^2.1.3    # Already added
  
  # Storage
  hive: ^2.2.3             # Already added
  hive_flutter: ^1.1.0     # Already added
```

### Backend (package.json)
```json
{
  "dependencies": {
    "express": "existing",
    "multer": "^1.4.5-lts.1",  // Handle audio file uploads
    "axios": "existing"
  }
}
```

---

## 📁 **Files to Create/Modify**

### ✅ **Flutter App**

#### NEW FILES:
1. `lib/models/audio_recording.dart` - Recording model
2. `lib/services/audio_recording_service.dart` - Recording logic
3. `lib/providers/audio_recording_provider.dart` - State management
4. `lib/screens/recordings_list_screen.dart` - Saved recordings list

#### MODIFIED FILES:
1. `lib/screens/audio_screen.dart` - Complete rewrite with Record UI
2. `lib/services/api_client.dart` - Add sendAudio() endpoint
3. `pubspec.yaml` - Add audio packages

---

### ✅ **Backend (Node.js)**

#### MODIFIED FILES:
1. `backend/server.js` - Add `/api/audio/send` endpoint
2. `backend/package.json` - Add multer for file uploads

---

### ✅ **Arduino**

#### MODIFIED FILES:
1. `arduino/smart_pendant_with_camera/smart_pendant_with_camera.ino`
   - Add `receiveAudio()` function
   - Add `playAudioFromBuffer()` function  
   - Add `/audio` HTTP endpoint handler

---

## 🎯 **Implementation Steps**

### **PHASE 1: Flutter App (7 files)**
- [ ] 1.1 Update pubspec.yaml with audio packages
- [ ] 1.2 Create audio_recording.dart model
- [ ] 1.3 Create audio_recording_service.dart
- [ ] 1.4 Create audio_recording_provider.dart
- [ ] 1.5 Rewrite audio_screen.dart with Record UI
- [ ] 1.6 Create recordings_list_screen.dart
- [ ] 1.7 Update api_client.dart with sendAudio()

### **PHASE 2: Backend (2 files)**
- [ ] 2.1 Update server.js with /api/audio/send endpoint
- [ ] 2.2 Update package.json

### **PHASE 3: Arduino (1 file)**
- [ ] 3.1 Add audio reception and playback to smart_pendant_with_camera.ino

---

## 🎨 **UI Flow**

```
┌──────────────────────────────────────┐
│      Audio Recording Screen          │
│                                      │
│  ┌────────────────────────────────┐ │
│  │   🎤   [Microphone Icon]       │ │
│  │                                 │ │
│  │   Ready to Record               │ │
│  │   00:00                         │ │
│  └────────────────────────────────┘ │
│                                      │
│  ┌──────────────────────────────┐  │
│  │      📕 RECORD                │  │  ← Tap to start recording
│  └──────────────────────────────┘  │
│                                      │
│  [ View Recordings List → ]          │
└──────────────────────────────────────┘

        ⬇️ (After Recording)

┌──────────────────────────────────────┐
│      Audio Recording Screen          │
│                                      │
│  ┌────────────────────────────────┐ │
│  │   🎵  [Waveform Animation]     │ │
│  │                                 │ │
│  │   Recording Saved              │ │
│  │   00:15                        │ │
│  └────────────────────────────────┘ │
│                                      │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌────┐ │
│  │ ▶️ │ │ ❌ │ │ 💾 │ │ 📤 │ │
│  │PLAY│ │CANCEL│ │ SAVE│ │SEND│ │
│  └──────┘ └──────┘ └──────┘ └────┘ │
│                                      │
│  [ View Recordings List → ]          │
└──────────────────────────────────────┘
```

---

## 🔊 **Arduino Audio Playback**

### Hardware Connection (from PIN_CONNECTIONS.md):
- **Audio Pin:** D7 (shared with panic button)
- **Amplifier:** PAM8403 (powered by 5V from LM2596)
- **Speaker:** 8Ω 1W connected to PAM8403 outputs

### Playback Method:
1. Receive base64-encoded PCM audio via HTTP POST to `/audio`
2. Decode base64 → raw PCM samples (16-bit, 8kHz mono)
3. Play using PWM on D7:
   ```cpp
   void playAudioSample(int16_t sample) {
     int pwm_value = map(sample, -32768, 32767, 0, 255);
     analogWrite(PANIC_AUDIO_PIN, pwm_value);
   }
   ```
4. Use 8kHz timer interrupt for smooth playback

---

## 📊 **Audio Format Specifications**

- **Sample Rate:** 8000 Hz (Arduino-friendly, saves bandwidth)
- **Bit Depth:** 16-bit PCM
- **Channels:** Mono
- **Encoding:** Base64 for transmission
- **Max Duration:** 30 seconds (240KB at 8kHz mono)

---

## ✅ **Testing Checklist**

### Flutter App:
- [ ] Record 5-second audio clip
- [ ] Playback recorded clip in app
- [ ] Save recording to list
- [ ] Delete recording from list
- [ ] Send recording to server
- [ ] Cancel recording before saving

### Backend:
- [ ] Receive audio POST request
- [ ] Validate audio data
- [ ] Forward to Arduino successfully
- [ ] Handle errors gracefully

### Arduino:
- [ ] Receive audio data via HTTP
- [ ] Decode base64 correctly
- [ ] Play audio through speaker
- [ ] Audio quality is understandable
- [ ] No audio distortion/clipping

---

## 🚀 **Ready to Implement?**

**Estimated Time:** 2-3 hours for full implementation

**Would you like me to proceed with the implementation?**

Type **"YES - START IMPLEMENTATION"** to begin, or let me know if you'd like any changes to this plan.
