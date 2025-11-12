# 🔌 PIN CONNECTION QUICK REFERENCE

## Arduino Nano ESP32 Pinout

```
                    ┌─────────────────┐
                    │   USB-C PORT    │
                    └─────────────────┘
                    │                 │
         ┌──────────┴─────────────────┴──────────┐
         │                                        │
         │      ARDUINO NANO ESP32               │
         │                                        │
    D13  │○ SCK (SPI)                      VIN ○ │
    D12  │○ MISO (SPI)                     GND ○ │
    D11  │○ MOSI (SPI)                   RESET ○ │
    D10  │○ ──→ CAM_RESET                   5V ○ │
    D9   │○ ──→ CAM_MCLK / PAM8403         A7 ○ │
    D8   │○ ──→ CAM_PCLK                   A6 ○ │──→ CAM_PWDN
    D7   │○ ──→ PANIC BUTTON               A5 ○ │──→ SCL (I²C)
    D6   │○ ──→ CAM_VS                     A4 ○ │──→ SDA (I²C)
    D5   │○ ──→ GPS TX (Arduino RX)        A3 ○ │──→ CAM_D5
    D4   │○ ──→ GPS RX (Arduino TX)        A2 ○ │──→ CAM_D4
    D3   │○ ──→ SIM7600E RX (not used)     A1 ○ │──→ CAM_D3
    D2   │○ ──→ SIM7600E TX (not used)     A0 ○ │──→ CAM_D2
    GND  │○                               3.3V ○ │
         │                                        │
         └────────────────────────────────────────┘
```

---

## 📊 Component Connection Table

### ✅ ADXL345 Accelerometer (I²C)
| ADXL345 Pin | Arduino Pin | Notes |
|-------------|-------------|-------|
| VCC         | 3.3V        | ⚠️ NOT 5V! Will damage sensor |
| GND         | GND         | Common ground |
| SDA         | A4 (GPIO18) | I²C data line |
| SCL         | A5 (GPIO19) | I²C clock line |

---

### 🌍 GPS Quectel L80 (UART)
| GPS Pin | Arduino Pin | Power Source | Notes |
|---------|-------------|--------------|-------|
| VCC     | —           | LM2596 5V    | Powered from buck converter |
| GND     | GND         | Common GND   | Share ground with Arduino |
| TX      | D5          | —            | GPS transmits → Arduino receives |
| RX      | D4          | —            | Arduino transmits → GPS receives |

---

### 🔘 Panic Button (Shared with Audio)
| Button Pin  | Arduino Pin | Notes |
|-------------|-------------|-------|
| One leg     | D7          | INPUT_PULLUP mode |
| Other leg   | GND         | Pressing = LOW signal |

💡 **No external resistor needed** - Arduino has internal pull-up resistor

---

### 🔊 PAM8403 Audio Amplifier + Speaker (Shared with Button)
| PAM8403 Pin | Connection      | Power Source | Notes |
|-------------|-----------------|--------------|-------|
| VCC         | —               | LM2596 5V    | Amplifier power |
| GND         | GND (common)    | —            | Share ground |
| L-IN        | D7 (shared!)    | —            | Shares pin with panic button |
| R-IN        | Not connected   | —            | Not used (mono audio) |
| SPK+ / SPK- | 8Ω 1W Speaker   | —            | Speaker output |

⚠️ **Special wiring:** Button and audio amplifier both connect to D7

---

### 📷 OV7670 Camera (Parallel Interface - 5 FPS Video)
| OV7670 Pin | Arduino Pin | Notes |
|------------|-------------|-------|
| VCC        | 3.3V        | ⚠️ Camera is 3.3V ONLY! |
| GND        | GND         | Common ground |
| MCLK       | D9          | Master clock (PWM @ 10 MHz) |
| PCLK       | D8          | Pixel clock input |
| VS (VSYNC) | D6          | Vertical sync (frame start) |
| HS (HREF)  | D11         | Horizontal sync (line valid) |
| D0         | D12         | Data bit 0 (LSB) |
| D1         | D13         | Data bit 1 |
| D2         | A0          | Data bit 2 |
| D3         | A1          | Data bit 3 |
| D4         | A2          | Data bit 4 |
| D5         | A3          | Data bit 5 |
| D6         | B0          | Data bit 6 |
| D7         | B1          | Data bit 7 (MSB) |
| SDA        | A4 (shared) | I²C configuration (shared with ADXL345) |
| SCL        | A5 (shared) | I²C configuration (shared with ADXL345) |
| RESET      | D10         | ⚠️ CRITICAL: Hardware reset control |
| PWDN       | A6          | ⚠️ CRITICAL: Power-down control |

✅ **FULL PARALLEL INTERFACE** - Captures images at 5 FPS (QQVGA 160x120)

---

### 🔋 Power System

#### From Laptop USB
- **Arduino Nano ESP32** ← USB-C cable
  - Provides 5V and 3.3V rails internally
  
#### From LM2596 Buck Converter
- **Input:** 12V DC adapter (1-2A)
- **Output:** Set to **5.0V** using adjustment screw
- **Powers:**
  - SIM7600E (5V, up to 2A)
  - GPS Quectel L80 (5V, ~50mA)
  - PAM8403 amplifier (5V, ~300mA)

⚠️ **CRITICAL:** Set LM2596 to exactly 5.0V BEFORE connecting components!

---

## 🔌 Breadboard Layout Guide

```
+5V Rail (from LM2596)   [═══════════════════════════]
                            ↓     ↓     ↓     ↓
                          GPS  SIM7600  PAM8403  (other 5V devices)

GND Rail                 [═══════════════════════════]
                            ↓     ↓     ↓     ↓     ↓
                         Arduino GPS SIM7600 PAM8403 ADXL345

3.3V Rail (from Arduino) [═══════════════════════════]
                            ↓           ↓
                         ADXL345    OV7670
```

### Connection Order (Recommended):
1. ✅ Connect all **GND** pins first (power rails)
2. ✅ Connect **3.3V** to ADXL345
3. ✅ Connect **I²C** (A4/A5) to ADXL345
4. ✅ Connect **panic button** to D7 and GND
5. ✅ Connect **GPS** to D4/D5 and LM2596 5V
6. ✅ Connect **PAM8403** to D9/D10 and LM2596 5V
7. ✅ Connect **speaker** to PAM8403 outputs
8. ⚠️ **Last:** Power up LM2596 and Arduino USB

---

## 🧪 Testing Each Component

### Test ADXL345 (I²C Scanner)
Upload this sketch to verify I²C connection:
```cpp
#include <Wire.h>

void setup() {
  Serial.begin(115200);
  Wire.begin(18, 19); // SDA=18, SCL=19
  
  Serial.println("I2C Scanner");
  for(byte addr = 1; addr < 127; addr++) {
    Wire.beginTransmission(addr);
    if(Wire.endTransmission() == 0) {
      Serial.print("Found device at 0x");
      Serial.println(addr, HEX);
    }
  }
}

void loop() {}
```
Expected output: `Found device at 0x53` (ADXL345 address)

---

### Test GPS (Serial Monitor)
```cpp
void setup() {
  Serial.begin(115200);
  Serial1.begin(9600, SERIAL_8N1, 5, 4); // RX=5, TX=4
}

void loop() {
  while(Serial1.available()) {
    Serial.write(Serial1.read());
  }
}
```
Expected output: NMEA sentences like `$GPGGA,123456.00,...`

---

### Test Button
```cpp
#define BUTTON_PIN 7

void setup() {
  Serial.begin(115200);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
}

void loop() {
  int state = digitalRead(BUTTON_PIN);
  Serial.println(state); // 1=not pressed, 0=pressed
  delay(100);
}
```

---

### Test Audio
```cpp
#define AUDIO_PIN 9

void setup() {
  pinMode(AUDIO_PIN, OUTPUT);
}

void loop() {
  tone(AUDIO_PIN, 1000); // 1kHz
  delay(500);
  noTone(AUDIO_PIN);
  delay(500);
}
```
Expected: Beep sound from speaker

---

## ⚠️ SAFETY WARNINGS

### ❌ DO NOT:
- Connect 5V to ADXL345 VCC (will damage sensor!)
- Connect 5V to OV7670 VCC (will damage camera!)
- Power SIM7600E from Arduino USB (will brownout)
- Power Arduino from LM2596 AND USB simultaneously
- Short circuit power rails

### ✅ DO:
- Use common ground for all components
- Check LM2596 output voltage before connecting (5.0V exactly)
- Use proper wire gauge for high-current paths (SIM7600E)
- Double-check polarity before powering on
- Test each component individually before full integration

---

## 🔧 Wire Color Code (Suggested)

| Color  | Use             |
|--------|-----------------|
| Red    | +5V power       |
| Orange | +3.3V power     |
| Black  | GND (ground)    |
| Yellow | I²C SDA (data)  |
| Green  | I²C SCL (clock) |
| Blue   | UART TX         |
| Purple | UART RX         |
| White  | Digital signals |
| Brown  | Audio signals   |

---

## 📝 Quick Troubleshooting

| Problem | Check These |
|---------|-------------|
| ADXL345 not detected | I²C wiring (A4/A5), 3.3V power, common GND |
| GPS no data | Serial wiring (D4/D5 reversed?), 5V power, baud rate 9600 |
| Button not working | Pull-up enabled in code, GND connection |
| No audio | Speaker polarity, PAM8403 power (5V), D9 connection |
| Arduino not powering | USB cable, USB port, Arduino not bricked |
| Brownouts/resets | Power supply insufficient, SIM7600E drawing too much |

---

**🔍 Always test components one at a time before full integration!**
