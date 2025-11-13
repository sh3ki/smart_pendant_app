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
    D13  │○ (available)                     VIN ○ │
    D12  │○ ──→ SCL (I²C ADXL345)          GND ○ │
    D11  │○ ──→ SDA (I²C ADXL345)        RESET ○ │
    D10  │○ (available)                      5V ○ │
    D9   │○ ──→ PAM8403 Audio              A7 ○ │──→ Battery Monitor (Voltage Divider)
    D8   │○ (available)                    A6 ○ │ (available)
    D7   │○ ──→ PANIC BUTTON               A5 ○ │ (available)
    D6   │○ (available)                    A4 ○ │ (available)
    D5   │○ ──→ GPS TX (Arduino RX)        A3 ○ │ (available)
    D4   │○ ──→ GPS RX (Arduino TX)        A2 ○ │ (available)
    D3   │○ ──→ SIM7600E TX (not used)     A1 ○ │ (available)
    D2   │○ ──→ SIM7600E RX (not used)     A0 ○ │ (available)
    GND  │○                               3.3V ○ │
         │                                        │
         └────────────────────────────────────────┘
```

---

## 📊 Component Connection Table

### ✅ ADXL345 Accelerometer (I²C)
| ADXL345 Pin | Arduino Pin | Power Source | Notes |
|-------------|-------------|--------------|-------|
| VCC         | —           | LM2596 3.3V  | Powered from 3.3V buck converter |
| GND         | GND         | Common GND   | Share ground with Arduino |
| **SDA**     | **D11**     | —            | Hardware I²C data line |
| **SCL**     | **D12**     | —            | Hardware I²C clock line |

⚠️ **CRITICAL:** On Arduino Nano ESP32, hardware I2C is on **D11/D12**, NOT A4/A5!  
💡 **No external pull-up resistors needed** - ADXL345 breakout boards have them built-in!

---

### 🌍 GPS Quectel L80 (UART)
| GPS Pin | Arduino Pin | Power Source | Notes |
|---------|-------------|--------------|-------|
| VCC     | —           | LM2596 5V    | Powered from buck converter |
| GND     | GND         | Common GND   | Share ground with Arduino |
| TX      | D5          | —            | GPS transmits → Arduino receives |
| RX      | D4          | —            | Arduino transmits → GPS receives |

---

### � SIM7600E 4G/LTE Module (UART - Optional)
| SIM7600E Pin | Arduino Pin | Power Source | Notes |
|--------------|-------------|--------------|-------|
| VCC (VBAT)   | —           | LM2596 5V    | **High current!** Up to 2A during transmission |
| GND          | GND         | Common GND   | Share ground with Arduino |
| TX           | D3          | —            | SIM7600E transmits → Arduino receives (not currently used) |
| RX           | D2          | —            | Arduino transmits → SIM7600E receives (not currently used) |
| PWR_KEY      | Manual      | —            | Press button to power on (2-3 seconds) |

⚠️ **CRITICAL:** SIM7600E requires **2A peak current** - must be powered from LM2596, NOT Arduino USB!

---

### 🔋 Battery Voltage Monitor (Voltage Divider on A7)
| Component       | Connection  | Value    | Notes |
|-----------------|-------------|----------|-------|
| Battery+ (8.4V) | → Resistor R1 | 10kΩ   | First resistor in divider |
| R1 other leg    | → A7 pin    | —        | Voltage measurement point |
| A7 pin          | → Resistor R2 | 4.7kΩ  | Second resistor in divider |
| R2 other leg    | → GND       | —        | Complete the divider |

**Circuit Diagram:**
```
Battery+ (8.4V max) ──[10kΩ]──┬── A7 (reads ~2.7V max)
                               │
                            [4.7kΩ]
                               │
                              GND
```

**Voltage Divider Formula:**
- V_out = V_in × (R2 / (R1 + R2))
- 8.4V × (4.7kΩ / 14.7kΩ) = 2.69V (safe for ESP32 ADC max 3.3V)

⚠️ **CRITICAL - Why resistors are REQUIRED:** 
- This is for **MEASURING** battery voltage, NOT powering anything!
- ESP32 ADC pin can only read 0-3.3V (will **DAMAGE** if you connect 8.4V directly!)
- Your 2 buck converters power the devices (3.3V and 5V)
- But you still need to **monitor** the battery level - that's what A7 + resistors do
- Without these resistors, connecting battery directly to A7 = **dead Arduino!**

---

### �🔘 Panic Button (Shared with Audio)
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
| L-IN        | D9              | —            | Audio PWM signal from Arduino |
| R-IN        | Not connected   | —            | Not used (mono audio) |
| SPK+ / SPK- | 8Ω 1W Speaker   | —            | Speaker output |

💡 **Audio output on D9, Panic button on D7** (separate pins)

---

### 🔋 Power System

#### Arduino Power
- **Arduino Nano ESP32** ← USB-C cable (for programming/testing)
- **OR** powered from 3.3V buck converter VIN pin (for standalone operation)

#### 2S Lithium Battery (7.4V nominal, 8.4V fully charged)
- **Input to TP5100 charger** (B+ and B- terminals)
- **12V DC adapter** → TP5100 (VIN+ and VIN-) for charging
  
#### LM2596 Buck Converter #1 (5V Output)
- **Input:** Battery+ and Battery- (6.0V-8.4V from battery)
- **Output:** Adjust to exactly **5.0V** using potentiometer
- **Powers:**
  - SIM7600E (5V, up to 2A peak)
  - GPS Quectel L80 (5V, ~50mA)
  - PAM8403 amplifier (5V, ~300mA)

#### LM2596 Buck Converter #2 (3.3V Output)
- **Input:** Battery+ and Battery- (6.0V-8.4V from battery)
- **Output:** Adjust to exactly **3.3V** using potentiometer
- **Powers:**
  - Arduino Nano ESP32 (3.3V, ~500mA)
  - ADXL345 accelerometer (3.3V, ~150μA)

⚠️ **CRITICAL:** 
- Set BOTH LM2596 outputs (5.0V and 3.3V) BEFORE connecting components!
- Use multimeter to verify voltages
- Connect battery through a fuse (3A recommended) and power switch

---

## 🔌 Breadboard Layout Guide

```
+5V Rail (from LM2596 #1)  [═══════════════════════════]
                              ↓        ↓        ↓
                            GPS    SIM7600   PAM8403

GND Rail (COMMON)          [═══════════════════════════]
                              ↓     ↓     ↓     ↓     ↓
                           Arduino GPS SIM7600 PAM8403 ADXL345

+3.3V Rail (from LM2596 #2)[═══════════════════════════]
                              ↓           ↓
                           Arduino     ADXL345
```

**Power Flow Diagram:**
```
Battery (7.4V)
    │
    ├──→ TP5100 Charger (charging circuit)
    │
    ├──→ LM2596 #1 → 5.0V  → GPS, SIM7600E, PAM8403
    │
    ├──→ LM2596 #2 → 3.3V  → Arduino, ADXL345
    │
    └──→ Voltage Divider (10kΩ + 4.7kΩ) → A7 (battery monitor)
```

### Connection Order (Recommended):
1. ✅ Connect all **GND** pins first (power rails)
2. ✅ Connect **3.3V** to ADXL345
3. ✅ Connect **I²C** (D11/D12) to ADXL345
4. ✅ Connect **panic button** to D7 and GND
5. ✅ Connect **voltage divider** resistors to A7 (10kΩ + 4.7kΩ)
6. ✅ Connect **GPS** to D4/D5 and LM2596 5V
7. ✅ Connect **SIM7600E** to D2/D3 and LM2596 5V (optional)
8. ✅ Connect **PAM8403** to D9 and LM2596 5V
9. ✅ Connect **speaker** to PAM8403 outputs
10. ⚠️ **Last:** Power up LM2596 and Arduino USB

---

## 🧪 Testing Each Component

### Test ADXL345 (I²C Scanner)
Upload this sketch to verify I²C connection:
```cpp
#include <Wire.h>

void setup() {
  Serial.begin(115200);
  Wire.begin(); // Use default I2C pins (D11=SDA, D12=SCL)
  
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

⚠️ **CRITICAL:** ADXL345 must be connected to **D11 (SDA)** and **D12 (SCL)**, NOT A4/A5!

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

### Test Battery Voltage Monitor
```cpp
#define BATTERY_PIN A7

void setup() {
  Serial.begin(115200);
  pinMode(BATTERY_PIN, INPUT);
}

void loop() {
  int adcValue = analogRead(BATTERY_PIN);
  float voltage_A7 = (adcValue / 4095.0) * 3.3; // ESP32 ADC is 12-bit (0-4095)
  float batteryVoltage = voltage_A7 * (14.7 / 4.7); // Reverse voltage divider
  
  Serial.print("ADC: ");
  Serial.print(adcValue);
  Serial.print(" | A7 Voltage: ");
  Serial.print(voltage_A7, 2);
  Serial.print("V | Battery: ");
  Serial.print(batteryVoltage, 2);
  Serial.println("V");
  
  delay(1000);
}
```
Expected output: Battery voltage 6.0V-8.4V (depends on charge level)

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
| ADXL345 not detected | I²C wiring (**D11/D12**, NOT A4/A5!), 3.3V power, common GND |
| GPS no data | Serial wiring (D4/D5 reversed?), 5V power, baud rate 9600 |
| Button not working | Pull-up enabled in code, GND connection |
| No audio | Speaker polarity, PAM8403 power (5V), D9 connection |
| Battery voltage wrong | Resistor values (10kΩ + 4.7kΩ), A7 connection, battery polarity |
| SIM7600E not powering on | 5V power from LM2596 (NOT Arduino!), PWR_KEY button press (2-3s) |
| Arduino not powering | USB cable, USB port, Arduino not bricked |
| Brownouts/resets | Power supply insufficient, SIM7600E drawing too much (needs 2A!) |

---

**🔍 Always test components one at a time before full integration!**
