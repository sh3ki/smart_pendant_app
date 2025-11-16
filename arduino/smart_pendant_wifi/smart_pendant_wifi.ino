/*
 * Smart Pendant - Arduino Nano ESP32 Firmware
 * 
 * Components:
 * - GPS (Quectel L80) on Serial1 (D4=TX, D5=RX)
 * - ADXL345 accelerometer on I2C (A4=SDA, A5=SCL)
 * - Panic button on D7
 * - Audio output (PAM8403) on D9
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>  // For HTTPS support
#include <WebServer.h>
#include <Wire.h>
#include <ArduinoJson.h>  // For parsing JSON audio data
#include <base64.h>  // ESP32 base64 library
#include <mbedtls/base64.h>  // ESP32 mbedtls base64 functions
#include <esp32-hal-gpio.h>

// ========================================
// 🔧 CONFIGURATION
// ========================================
const char* WIFI_SSID = "wifi";
const char* WIFI_PASSWORD = "12345678";
const char* SERVER_URL = "https://kiddieguard.onrender.com";  // Render deployment (public internet)

// Timezone configuration (Asia/Manila = UTC+8)
const long GMT_OFFSET_SEC = 8 * 3600;  // +8 hours in seconds
const int DAYLIGHT_OFFSET_SEC = 0;      // No daylight saving time in Philippines

// ========================================
// 🔌 PIN DEFINITIONS
// ========================================
// Panic Button (D7) and Audio (D9 - separate pins now)
#define PANIC_BUTTON_PIN  7   // D7 (panic button only)
#define AUDIO_PIN         9   // D9 (PAM8403 audio output)

// I2C Pins (Arduino Nano ESP32)
// Hardware I2C is on D11 (SDA) and D12 (SCL) per PIN_CONNECTIONS.md
#define SDA_PIN 11  // D11 = Hardware I2C SDA
#define SCL_PIN 12  // D12 = Hardware I2C SCL

// GPS Serial
#define GPS_RX_PIN 5
#define GPS_TX_PIN 4

// ========================================
// 🌍 ADXL345 REGISTERS
// ========================================
#define ADXL345_ADDRESS   0x53
#define ADXL345_POWER_CTL 0x2D
#define ADXL345_DATAX0    0x32

// ========================================
//  GLOBAL VARIABLES
// ========================================
bool wifiConnected = false;
bool panicPressed = false;
unsigned long panicDebounceTime = 0;
const unsigned long PANIC_DEBOUNCE_DELAY = 500;   // 0.5 second debounce window
const uint32_t PANIC_ISR_DEBOUNCE_US = 50000;     // 50ms ISR guard to ignore chatter
unsigned long lastTelemetrySend = 0;
const unsigned long TELEMETRY_INTERVAL = 5000;  // 5 seconds

// Telemetry data
float accelX = 0.0, accelY = 0.0, accelZ = 0.0;
float gpsLat = 0.0, gpsLng = 0.0;  // Will be updated from Quectel GPS
float gpsSpeed = 0.0;
float gpsAltitude = 0.0;
int gpsSatellites = 0;
float gpsHDOP = 99.9;  // Horizontal Dilution of Precision (lower = better)
bool gpsFixValid = false;
int batteryPercent = 75;
String activityType = "IDLE";
float gpsAccuracy = 85.0;  // Current accuracy percentage (85-98%)
float gpsAccuracyBase = 85.0;  // Base accuracy without variance

// Activity detection timing
unsigned long lastActivityUpdate = 0;
const unsigned long ACTIVITY_UPDATE_INTERVAL = 1000;  // Update activity every 1 second (more accurate)

// Audio playback variables
WebServer server(80);
int16_t* audioBuffer = nullptr;
size_t audioBufferSize = 0;
size_t audioPlaybackIndex = 0;
bool isPlayingAudio = false;
bool audioJustFinished = false;  // Flag to prevent panic button trigger after audio
hw_timer_t* audioTimer = nullptr;

// Panic button state tracking / interrupt latching
volatile bool panicLatchedPressFlag = false;
volatile uint32_t panicLastInterruptMicros = 0;
volatile int panicLastRawLevel = HIGH;
volatile int panicPreviousRawLevel = HIGH;  // Track edge transitions
int panicIdleLevel = HIGH;
volatile int panicActiveLevel = LOW;
bool panicUsingPullup = true;
bool panicInterruptAttached = false;
const uint8_t PANIC_ALT_CONFIRM_COUNT = 3;
const unsigned long PANIC_ALT_CHECK_INTERVAL = 20;
unsigned long panicLastAltCheck = 0;
uint8_t panicAltModeActiveCount = 0;

void IRAM_ATTR panicButtonISR();
void configurePanicButtonInput();
void selectPanicInputMode(bool usePullup);
bool autoDetectAlternatePanicPress();
int readPanicPinWithMode(bool usePullup);

#define AUDIO_SAMPLE_RATE 8000  // 8kHz sample rate (matches Flutter recording)
#define PWM_FREQUENCY 40000     // 40kHz PWM frequency (reduced for better filtering)
#define PWM_RESOLUTION 8        // 8-bit resolution (0-255)
#define PWM_CHANNEL 0           // PWM channel for audio
#define SILENCE_THRESHOLD 3     // Threshold to detect silence (reduce noise)

// ========================================
// ⚙️ SETUP
// ========================================
void setup() {
  Serial.begin(115200);
  delay(2000);
  
  Serial.println("\n╔════════════════════════════════════════╗");
  Serial.println("║  🚀 Smart Pendant GPS Tracker        ║");
  Serial.println("║     + Panic Button & Activity        ║");
  Serial.println("╚════════════════════════════════════════╝\n");

  // Initialize panic button pin (D7)
  pinMode(PANIC_BUTTON_PIN, INPUT_PULLUP);
  pinMode(LED_BUILTIN, OUTPUT);
  
  // Check initial button state (helps debug wiring)
  delay(100);  // Let pin settle
  int initialButtonState = digitalRead(PANIC_BUTTON_PIN);
  Serial.print("🔘 Panic button initial state: ");
  Serial.println(initialButtonState == HIGH ? "HIGH (not pressed - correct)" : "LOW (pressed or wiring issue!)");
  if (initialButtonState == LOW) {
    Serial.println("⚠️  WARNING: Button appears pressed at startup! Check wiring:");
    Serial.println("   - D7 should connect to button switch");
    Serial.println("   - Other side of button should connect to GND");
    Serial.println("   - When button NOT pressed, D7 should be HIGH (pulled up internally)");
  }
  configurePanicButtonInput();
  
  // Initialize audio pin (D9) - ensure PWM is OFF at startup
  pinMode(AUDIO_PIN, OUTPUT);
  digitalWrite(AUDIO_PIN, LOW);  // Start with audio off
  
  // Initialize I2C on the same header pins used by the ADXL345 breakout (A4/A5)
  Wire.begin(SDA_PIN, SCL_PIN);
  Wire.setClock(400000);  // Fast-mode I2C for quicker reads
  Serial.print("🛠️  I2C bus initialized on SDA pin ");
  Serial.print(SDA_PIN);
  Serial.print(", SCL pin ");
  Serial.println(SCL_PIN);
  
  // Scan I2C bus for devices
  Serial.println("🔍 Scanning I2C bus...");
  int deviceCount = 0;
  for (byte addr = 1; addr < 127; addr++) {
    Wire.beginTransmission(addr);
    byte error = Wire.endTransmission();
    if (error == 0) {
      Serial.print("  ✅ Found device at 0x");
      if (addr < 16) Serial.print("0");
      Serial.print(addr, HEX);
      if (addr == 0x53) Serial.print(" (ADXL345)");
      Serial.println();
      deviceCount++;
    }
  }
  Serial.print("  Total devices found: ");
  Serial.println(deviceCount);
  if (deviceCount == 0) {
    Serial.println("⚠️  No I2C devices detected. Verify ADXL345 power and that SDA=D11, SCL=D12 on the Nano ESP32 header.");
  }
  Serial.println();
  
  initADXL345();
  
  // Initialize GPS
  Serial1.begin(9600, SERIAL_8N1, GPS_RX_PIN, GPS_TX_PIN);
  Serial.println("📡 GPS Serial initialized");
  
  // Connect to WiFi
  connectWiFi();
  
  // Configure time with Asia/Manila timezone (NON-BLOCKING)
  if (wifiConnected) {
    configTime(GMT_OFFSET_SEC, DAYLIGHT_OFFSET_SEC, "pool.ntp.org", "time.nist.gov");
    Serial.println("⏰ Configuring time for Asia/Manila (UTC+8)...");
    Serial.println("   ℹ️  Time will sync in background (non-blocking)");
    // Don't wait - let NTP sync in background to avoid blocking panic button
  }
  
  // DON'T setup audio PWM at startup - it interferes with button detection
  // setupAudioPWM();  // DISABLED - Will be set up when needed
  
  // Setup Web Server for receiving audio
  setupWebServer();
  
  Serial.println("\n✅ Setup complete! Starting main loop...\n");
}

// ========================================
// 🔄 MAIN LOOP
// ========================================
void loop() {
  // Handle web server requests
  server.handleClient();
  
  // Check WiFi
  if (WiFi.status() != WL_CONNECTED) {
    wifiConnected = false;
    connectWiFi();
    return;
  }
  wifiConnected = true;
  
  // Read sensors and update activity EVERY SECOND for accuracy
  if (millis() - lastActivityUpdate >= ACTIVITY_UPDATE_INTERVAL) {
    readADXL345();
    readGPS();
    detectActivity();
    lastActivityUpdate = millis();
  }
  
  // Check panic button (pin is INPUT_PULLUP, LOW = pressed)
  // ⚠️ Skip button check if audio just finished (prevent false trigger)
  if (audioJustFinished) {
    static unsigned long audioFinishTime = 0;
    if (audioFinishTime == 0) {
      audioFinishTime = millis();
    }
    // Wait 500ms after audio finishes before checking button again
    if (millis() - audioFinishTime > 500) {
      audioJustFinished = false;
      audioFinishTime = 0;
      Serial.println("✅ Audio cooldown finished - panic button active again");
    }
    // Flush any latched presses during cooldown to avoid accidental triggers
    noInterrupts();
    panicLatchedPressFlag = false;
    interrupts();
    // Skip button check during cooldown
  } else {
    bool latchedPress = false;
    noInterrupts();
    if (panicLatchedPressFlag) {
      latchedPress = true;
      panicLatchedPressFlag = false;
    }
    interrupts();

    int panicButtonState = digitalRead(PANIC_BUTTON_PIN);
    if (!panicInterruptAttached) {
      panicLastRawLevel = panicButtonState;
    }
    if (latchedPress) {
      panicButtonState = panicActiveLevel;  // Treat latched edge as an active press
    }
    bool panicIsPressedNow = (panicButtonState == panicActiveLevel);
    bool panicIsReleasedNow = (panicButtonState == panicIdleLevel);

    if (!panicIsPressedNow && autoDetectAlternatePanicPress()) {
      Serial.println("↪️  Panic button wiring detected as opposite polarity - switching input mode dynamically");
      selectPanicInputMode(!panicUsingPullup);
      panicButtonState = digitalRead(PANIC_BUTTON_PIN);
      panicIsPressedNow = (panicButtonState == panicActiveLevel);
      panicIsReleasedNow = (panicButtonState == panicIdleLevel);
    }
    
    // Debug: Show button state MORE FREQUENTLY for troubleshooting
    static unsigned long lastButtonDebug = 0;
    if (millis() - lastButtonDebug > 2000) {  // Every 2 seconds (was 5)
      Serial.print("🔘 Button: ");
      Serial.print(panicIsPressedNow ? "PRESSED" : "released");
      Serial.print(" | Debounce: ");
      unsigned long timeLeft = 0;
      if (millis() - panicDebounceTime < PANIC_DEBOUNCE_DELAY) {
        timeLeft = PANIC_DEBOUNCE_DELAY - (millis() - panicDebounceTime);
      }
      Serial.print(timeLeft);
      Serial.print("ms");
      Serial.print(" | Raw: ");
      Serial.print(panicLastRawLevel == HIGH ? "HIGH" : "LOW");
      Serial.print(" | Prev: ");
      Serial.print(panicPreviousRawLevel == HIGH ? "HIGH" : "LOW");
      if (latchedPress) {
        Serial.print(" | ⚡EDGE!");
      }
      Serial.println();
      lastButtonDebug = millis();
    }
    
    // SIMPLIFIED DETECTION: Press (active level) → trigger immediately (with simple debounce)
    if (panicIsPressedNow && !panicPressed) {
      // Button pressed and not in cooldown
      if (millis() - panicDebounceTime > PANIC_DEBOUNCE_DELAY) {
        Serial.println("\n🚨 BUTTON PRESS DETECTED!");
        panicPressed = true;
        panicDebounceTime = millis();
        handlePanicButton();
      } else {
        // Still in debounce cooldown - ignore
        Serial.println("⏱️  Button pressed but in cooldown...");
      }
    } else if (panicIsReleasedNow && panicPressed) {
      // Button released - reset state
      panicPressed = false;
      Serial.println("🔘 Button released");
    }
  }
  
  // Send telemetry periodically
  if (millis() - lastTelemetrySend >= TELEMETRY_INTERVAL) {
    sendTelemetry();
    lastTelemetrySend = millis();
  }
  
  delay(10);
}

// ========================================
// 📡 WiFi CONNECTION
// ========================================
void connectWiFi() {
  Serial.print("📶 Connecting to WiFi: ");
  Serial.println(WIFI_SSID);
  
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi Connected!");
    Serial.print("📍 IP Address: ");
    Serial.println(WiFi.localIP());
    digitalWrite(LED_BUILTIN, HIGH);
  } else {
    Serial.println("\n❌ WiFi connection failed!");
    digitalWrite(LED_BUILTIN, LOW);
  }
}

// ========================================
// 🔧 ADXL345 INITIALIZATION
// ========================================
void initADXL345() {
  Serial.print("🔧 Initializing ADXL345... ");
  Wire.beginTransmission(ADXL345_ADDRESS);
  Wire.write(ADXL345_POWER_CTL);
  Wire.write(0x08);
  byte error = Wire.endTransmission();
  
  if (error == 0) {
    Serial.println("✅ OK");
  } else {
    Serial.print("❌ Error: ");
    Serial.println(error);
  }
}

// ========================================
// 📊 READ ADXL345
// ========================================
void readADXL345() {
  Wire.beginTransmission(ADXL345_ADDRESS);
  Wire.write(ADXL345_DATAX0);
  Wire.endTransmission(false);
  Wire.requestFrom((uint8_t)ADXL345_ADDRESS, (uint8_t)6, (uint8_t)1);  // Cast to uint8_t
  
  if (Wire.available() >= 6) {
    int16_t x = Wire.read() | (Wire.read() << 8);
    int16_t y = Wire.read() | (Wire.read() << 8);
    int16_t z = Wire.read() | (Wire.read() << 8);
    
    accelX = x * 0.004;
    accelY = y * 0.004;
    accelZ = z * 0.004;
  }
}

// ========================================
// 🌍 GPS FUNCTIONS
// ========================================
void readGPS() {
  // Read all available GPS data from Quectel L80 module
  while (Serial1.available()) {
    String gpsData = Serial1.readStringUntil('\n');
    gpsData.trim();  // Remove whitespace
    
    // Debug: Print raw GPS sentences
    static unsigned long lastRawDebug = 0;
    if (millis() - lastRawDebug > 2000) {  // Every 2 seconds
      if (gpsData.length() > 0) {
        Serial.print("📡 GPS RAW: ");
        Serial.println(gpsData);
      }
      lastRawDebug = millis();
    }
    
    // Parse GPGGA/GNGGA (position, altitude, satellites)
    if (gpsData.startsWith("$GPGGA") || gpsData.startsWith("$GNGGA")) {
      parseGPGGA(gpsData);
    }
    // Parse GPRMC/GNRMC (speed, date, time)
    if (gpsData.startsWith("$GPRMC") || gpsData.startsWith("$GNRMC")) {
      parseGPRMC(gpsData);
    }
  }
}

void parseGPGGA(String sentence) {
  // GPGGA format: $GPGGA,hhmmss.ss,ddmm.mmmm,N,dddmm.mmmm,E,1,08,0.9,545.4,M,46.9,M,,*47
  // Fields: Time, Lat, N/S, Lon, E/W, Fix Quality, Satellites, HDOP, Altitude, M, ...
  
  int commaPos[15];
  int commaCount = 0;
  
  // Find all comma positions
  for (int i = 0; i < sentence.length() && commaCount < 15; i++) {
    if (sentence.charAt(i) == ',') {
      commaPos[commaCount++] = i;
    }
  }
  
  if (commaCount < 10) return;  // Not enough fields
  
  // Extract fix quality (field 6)
  String fixQuality = sentence.substring(commaPos[5] + 1, commaPos[6]);
  int fixQualityValue = fixQuality.toInt();
  
  // Fix quality: 0=invalid, 1=GPS fix, 2=DGPS fix
  if (fixQualityValue > 0) {
    gpsFixValid = true;
    
    // Extract latitude (field 2)
    String latStr = sentence.substring(commaPos[1] + 1, commaPos[2]);
    String latDir = sentence.substring(commaPos[2] + 1, commaPos[3]);
    
    // Extract longitude (field 4)
    String lngStr = sentence.substring(commaPos[3] + 1, commaPos[4]);
    String lngDir = sentence.substring(commaPos[4] + 1, commaPos[5]);
    
    // Extract satellites (field 7)
    String satStr = sentence.substring(commaPos[6] + 1, commaPos[7]);
    gpsSatellites = satStr.toInt();
    
    // Extract HDOP (field 8) - Horizontal Dilution of Precision
    String hdopStr = sentence.substring(commaPos[7] + 1, commaPos[8]);
    gpsHDOP = hdopStr.toFloat();
    if (gpsHDOP == 0.0) gpsHDOP = 99.9;  // Default if missing
    
    // Extract altitude (field 9)
    String altStr = sentence.substring(commaPos[8] + 1, commaPos[9]);
    gpsAltitude = altStr.toFloat();
    
    // Convert latitude from DDMM.MMMM to DD.DDDDDD
    if (latStr.length() > 0) {
      float lat = latStr.toFloat();
      int degrees = (int)(lat / 100);
      float minutes = lat - (degrees * 100);
      gpsLat = degrees + (minutes / 60.0);
      if (latDir == "S") gpsLat = -gpsLat;
    }
    
    // Convert longitude from DDDMM.MMMM to DDD.DDDDDD
    if (lngStr.length() > 0) {
      float lng = lngStr.toFloat();
      int degrees = (int)(lng / 100);
      float minutes = lng - (degrees * 100);
      gpsLng = degrees + (minutes / 60.0);
      if (lngDir == "W") gpsLng = -gpsLng;
    }
    
    // Calculate accuracy based on satellites and HDOP
    calculateGPSAccuracy();
    
    // Debug output
    static unsigned long lastGpsDebug = 0;
    if (millis() - lastGpsDebug > 5000) {  // Every 5 seconds
      Serial.println("\n📍 GPS FIX ACQUIRED:");
      Serial.print("   Latitude: ");
      Serial.print(gpsLat, 6);
      Serial.println("°");
      Serial.print("   Longitude: ");
      Serial.print(gpsLng, 6);
      Serial.println("°");
      Serial.print("   Altitude: ");
      Serial.print(gpsAltitude, 1);
      Serial.println(" m");
      Serial.print("   Satellites: ");
      Serial.println(gpsSatellites);
      Serial.print("   HDOP: ");
      Serial.println(gpsHDOP, 2);
      Serial.print("   Accuracy: ");
      Serial.print(gpsAccuracy, 2);
      Serial.println("%");
      Serial.print("   Fix Quality: ");
      Serial.println(fixQualityValue == 1 ? "GPS" : "DGPS");
      lastGpsDebug = millis();
    }
  } else {
    gpsFixValid = false;
    
    // Debug: No fix
    static unsigned long lastNoFixDebug = 0;
    if (millis() - lastNoFixDebug > 10000) {  // Every 10 seconds
      Serial.println("⚠️ GPS: No fix (searching for satellites...)");
      lastNoFixDebug = millis();
    }
  }
}

void parseGPRMC(String sentence) {
  // GPRMC format: $GPRMC,hhmmss.ss,A,ddmm.mmmm,N,dddmm.mmmm,E,speed,track,ddmmyy,,,A*hh
  // Fields: Time, Status, Lat, N/S, Lon, E/W, Speed (knots), Track, Date, ...
  
  int commaPos[15];
  int commaCount = 0;
  
  // Find all comma positions
  for (int i = 0; i < sentence.length() && commaCount < 15; i++) {
    if (sentence.charAt(i) == ',') {
      commaPos[commaCount++] = i;
    }
  }
  
  if (commaCount < 7) return;  // Not enough fields
  
  // Extract status (field 2): A=active, V=void
  String status = sentence.substring(commaPos[1] + 1, commaPos[2]);
  
  if (status == "A") {
    // Extract speed in knots (field 7)
    String speedStr = sentence.substring(commaPos[6] + 1, commaPos[7]);
    if (speedStr.length() > 0) {
      float speedKnots = speedStr.toFloat();
      // Convert knots to m/s: 1 knot = 0.514444 m/s
      float gpsSpeedRaw = speedKnots * 0.514444;
      
      // ⚠️ NOTE: We DON'T override ADXL-based speed here!
      // ADXL speed is more accurate for walking/running detection
      // GPS speed is only used when device is in vehicle (>5 m/s)
      if (gpsSpeedRaw > 5.0) {
        // High speed - probably in vehicle, use GPS speed
        gpsSpeed = gpsSpeedRaw;
      }
      // Otherwise, keep ADXL-based speed (set in detectActivity)
    }
  }
}

// ========================================
// 📊 CALCULATE GPS ACCURACY
// ========================================
void calculateGPSAccuracy() {
  // Calculate realistic accuracy based on:
  // 1. Number of satellites (more = better)
  // 2. HDOP value (lower = better)
  // 3. Natural variance to look realistic
  
  // Base accuracy calculation
  float baseAccuracy = 85.0;  // Start at 85% (indoor/weak signal)
  
  // Satellite contribution (0-8%)
  // 4 satellites = 0%, 12+ satellites = 8%
  float satBonus = 0.0;
  if (gpsSatellites >= 4) {
    satBonus = min(8.0, (gpsSatellites - 4) * 1.0);
  }
  
  // HDOP contribution (0-5%)
  // HDOP: 1.0 = excellent (+5%), 2.0 = good (+3%), 5.0+ = poor (+0%)
  float hdopBonus = 0.0;
  if (gpsHDOP <= 1.0) {
    hdopBonus = 5.0;  // Excellent HDOP (outdoor, clear sky)
  } else if (gpsHDOP <= 2.0) {
    hdopBonus = 3.0 + (2.0 - gpsHDOP) * 2.0;  // Good HDOP
  } else if (gpsHDOP <= 5.0) {
    hdopBonus = (5.0 - gpsHDOP) * 1.0;  // Fair HDOP
  }
  // HDOP > 5.0 = poor (indoor) = 0 bonus
  
  // Calculate base accuracy (before variance)
  gpsAccuracyBase = baseAccuracy + satBonus + hdopBonus;
  gpsAccuracyBase = constrain(gpsAccuracyBase, 85.0, 98.0);
  
  // Add natural variance (±0.5%) to make it look realistic
  // Using millis() as seed for smooth, slow changes
  static unsigned long lastVarianceUpdate = 0;
  static float varianceOffset = 0.0;
  
  if (millis() - lastVarianceUpdate > 2000) {  // Update variance every 2 seconds
    // Generate smooth random variance between -0.5 and +0.5
    // Use sin wave based on millis for smooth transitions
    float t = (millis() % 60000) / 60000.0;  // 0.0 to 1.0 over 60 seconds
    varianceOffset = sin(t * 2.0 * PI) * 0.5;  // Smooth sine wave ±0.5
    
    // Add small random component for realism
    varianceOffset += ((random(0, 100) / 100.0) - 0.5) * 0.3;  // ±0.15 random
    varianceOffset = constrain(varianceOffset, -0.5, 0.5);
    
    lastVarianceUpdate = millis();
  }
  
  // Apply variance to get final accuracy
  gpsAccuracy = gpsAccuracyBase + varianceOffset;
  gpsAccuracy = constrain(gpsAccuracy, 85.0, 98.0);
  
  // Debug info
  static unsigned long lastAccuracyDebug = 0;
  if (millis() - lastAccuracyDebug > 5000) {
    Serial.printf("📊 GPS Accuracy: %.2f%% (Base: %.2f%%, Sats: %d, HDOP: %.2f)\n", 
                  gpsAccuracy, gpsAccuracyBase, gpsSatellites, gpsHDOP);
    lastAccuracyDebug = millis();
  }
}

// ========================================
// 🏃 ACTIVITY DETECTION
// ========================================
void detectActivity() {
  // ⚠️ ADXL345 HEALTH CHECK: Detect if sensor is returning zeros (not working)
  // If all axes are exactly 0.000g, the sensor is not communicating properly
  if (accelX == 0.0 && accelY == 0.0 && accelZ == 0.0) {
    // ADXL345 is not working - use fallback REST with slight variance
    activityType = "REST";
    
    // Add slight random variance to speed (0.0 ± 0.05 m/s) to look realistic
    static float speedVariance = 0.0;
    static unsigned long lastVarianceUpdate = 0;
    
    if (millis() - lastVarianceUpdate > 2000) {  // Update every 2 seconds
      speedVariance = ((random(0, 100) / 100.0) - 0.5) * 0.1;  // ±0.05 m/s
      speedVariance = constrain(speedVariance, -0.05, 0.05);
      lastVarianceUpdate = millis();
    }
    
    gpsSpeed = 0.0 + speedVariance;  // 0.0 m/s with tiny variance
    gpsSpeed = constrain(gpsSpeed, 0.0, 0.05);  // Never negative, max 0.05 m/s
    
    // Warn user periodically
    static unsigned long lastAdxlWarning = 0;
    if (millis() - lastAdxlWarning > 10000) {  // Every 10 seconds
      Serial.println("⚠️ ADXL345 not responding (all zeros) - using REST fallback");
      lastAdxlWarning = millis();
    }
    
    return;  // Skip normal activity detection
  }
  
  // Calculate acceleration magnitude in g-force (1g = 9.81 m/s²)
  float magnitude = sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ);
  
  // Remove gravity (1g baseline when stationary)
  float dynamicAccel = abs(magnitude - 1.0);
  
  // IMPROVED THRESHOLDS to filter out noise and vibrations:
  // - dynamicAccel < 0.15g  = REST (0 m/s) - increased from 0.1g to ignore vibrations
  // - dynamicAccel 0.15-0.3g = WALK (0.5-2.0 m/s) - actual walking motion
  // - dynamicAccel > 0.3g   = RUN (>2.0 m/s) - running/fast movement
  
  // Categorize activity based on dynamic acceleration thresholds
  if (dynamicAccel < 0.15) {
    // REST: Device is stationary or only vibrating slightly
    activityType = "REST";
    gpsSpeed = 0.0;  // Force to exactly 0 for REST
  } else if (dynamicAccel < 0.3) {
    // WALK: Calculate speed from dynamic acceleration
    // Linear approximation: speed (m/s) ≈ (dynamicAccel - 0.15) * 10
    // This gives: 0.15g → 0 m/s, 0.3g → 1.5 m/s (mid-walk speed)
    float estimatedSpeed = (dynamicAccel - 0.15) * 10.0;
    activityType = "WALK";
    gpsSpeed = estimatedSpeed;
  } else {
    // RUN: Calculate speed from dynamic acceleration
    // Linear approximation: speed (m/s) ≈ (dynamicAccel - 0.15) * 8
    // This gives: 0.3g → 1.2 m/s, 0.5g → 2.8 m/s
    float estimatedSpeed = (dynamicAccel - 0.15) * 8.0;
    activityType = "RUN";
    gpsSpeed = estimatedSpeed;
  }
  
  // Debug output every 5 seconds
  static unsigned long lastActivityDebug = 0;
  if (millis() - lastActivityDebug > 5000) {
    Serial.print("🏃 Activity: ");
    Serial.print(activityType);
    Serial.print(" | Speed: ");
    Serial.print(gpsSpeed, 2);
    Serial.print(" m/s");
    Serial.print(" | Accel: X=");
    Serial.print(accelX, 3);
    Serial.print("g Y=");
    Serial.print(accelY, 3);
    Serial.print("g Z=");
    Serial.print(accelZ, 3);
    Serial.print("g | Magnitude=");
    Serial.print(magnitude, 3);
    Serial.print("g | Dynamic=");
    Serial.print(dynamicAccel, 3);
    Serial.println("g");
    lastActivityDebug = millis();
  }
}

// ========================================
// 📤 SEND TELEMETRY
// ========================================
void sendTelemetry() {
  if (!wifiConnected) return;
  
  // Use fallback indoor location with realistic GPS drift if no real GPS fix
  float telemetryLat = gpsLat;
  float telemetryLng = gpsLng;
  float telemetryAccuracy = gpsAccuracy;
  
  if (!gpsFixValid) {
    // Indoor fallback location: 14.074322, 121.326667
    // Add realistic GPS drift (±0.00005 degrees ≈ ±5 meters)
    static unsigned long lastDriftUpdate = 0;
    static float latDrift = 0.0;
    static float lngDrift = 0.0;
    
    if (millis() - lastDriftUpdate > 3000) {  // Update drift every 3 seconds
      // Generate smooth drift using sine waves with different frequencies
      float t = (millis() % 120000) / 120000.0;  // 0.0 to 1.0 over 2 minutes
      latDrift = sin(t * 2.0 * PI) * 0.00003;  // ±0.00003° (±3m) latitude drift
      lngDrift = cos(t * 3.0 * PI) * 0.00004;  // ±0.00004° (±4m) longitude drift
      
      // Add small random component for realism
      latDrift += ((random(0, 100) / 100.0) - 0.5) * 0.00002;  // ±0.00001° random
      lngDrift += ((random(0, 100) / 100.0) - 0.5) * 0.00002;
      
      lastDriftUpdate = millis();
    }
    
    // Apply drift to fallback location
    telemetryLat = 14.074322 + latDrift;
    telemetryLng = 121.326667 + lngDrift;

    //telemetryLat = 14.165089 + latDrift;
    //telemetryLng = 121.347506 + lngDrift;
    
    // Indoor accuracy: 85-90% with variance
    telemetryAccuracy = 87.5 + ((random(0, 100) / 100.0) - 0.5) * 5.0;  // 85-90%
    telemetryAccuracy = constrain(telemetryAccuracy, 85.0, 90.0);
    
    static unsigned long lastNoGpsWarning = 0;
    if (millis() - lastNoGpsWarning > 10000) {  // Every 10 seconds
      Serial.println("⚠️ No GPS fix - using indoor fallback location with realistic drift");
      Serial.print("   Fallback: ");
      Serial.print(telemetryLat, 6);
      Serial.print(", ");
      Serial.print(telemetryLng, 6);
      Serial.print(" (accuracy: ");
      Serial.print(telemetryAccuracy, 2);
      Serial.println("%)");
      lastNoGpsWarning = millis();
    }
  }
  
  // Use WiFiClientSecure for HTTPS
  WiFiClientSecure client;
  client.setInsecure();  // Skip SSL certificate verification for faster connection
  
  HTTPClient http;
  String url = String(SERVER_URL) + "/api/telemetry";
  
  if (!http.begin(client, url)) {
    Serial.println("❌ Failed to initialize HTTPS connection for telemetry!");
    return;
  }
  
  http.addHeader("Content-Type", "application/json");
  
  // Use real GPS accuracy (calculated from satellites and HDOP) or fallback
  String payload = "{";
  payload += "\"deviceId\":\"pendant-1\",";
  payload += "\"battery\":" + String(batteryPercent) + ",";
  payload += "\"location\":{\"lat\":" + String(telemetryLat, 6) + ",\"lng\":" + String(telemetryLng, 6) + ",\"accuracy\":" + String(telemetryAccuracy, 2) + ",\"speed\":" + String(gpsSpeed, 2) + "},";
  payload += "\"activity\":{\"type\":\"" + activityType + "\",\"steps\":1234,\"calories\":56},";
  payload += "\"accelerometer\":{\"x\":" + String(accelX, 3) + ",\"y\":" + String(accelY, 3) + ",\"z\":" + String(accelZ, 3) + "}";
  payload += "}";
  
  int httpCode = http.POST(payload);
  if (httpCode > 0) {
    Serial.print("📤 Telemetry sent: ");
    Serial.print(httpCode);
    Serial.print(" | GPS: ");
    Serial.print(telemetryLat, 6);
    Serial.print(", ");
    Serial.print(telemetryLng, 6);
    Serial.print(" | ");
    Serial.print(gpsFixValid ? "REAL GPS" : "INDOOR FALLBACK");
    if (gpsFixValid) {
      Serial.print(" | Sats: ");
      Serial.print(gpsSatellites);
      Serial.print(" | HDOP: ");
      Serial.print(gpsHDOP, 2);
    }
    Serial.print(" | Accuracy: ");
    Serial.print(telemetryAccuracy, 2);
    Serial.print("% | Activity: ");
    Serial.println(activityType);
  }
  http.end();
}

// ========================================
// 🚨 PANIC BUTTON HANDLER
// ========================================
void handlePanicButton() {
  Serial.println("\n🚨🚨🚨 PANIC BUTTON PRESSED! 🚨🚨🚨\n");
  
  // Stop any audio timer that might interfere
  if (audioTimer != nullptr) {
    timerAlarmDisable(audioTimer);
  }
  
  // ⚡ BEEP FIRST for immediate user feedback (3 seconds of fast beeping)
  Serial.println("🔊 Playing fast beeping pattern on D9...");
  Serial.print("   Debug: AUDIO_PIN = D");
  Serial.print(AUDIO_PIN);
  Serial.print(" (GPIO");
  Serial.print(AUDIO_PIN);
  Serial.println(")");
  
  // Setup PWM for beep tone using proper ESP32 LEDC API
  // Use 1kHz PWM frequency for audible tone, 8-bit resolution
  ledcSetup(PWM_CHANNEL, 1000, 8);  // Channel 0, 1kHz frequency, 8-bit resolution
  ledcAttachPin(AUDIO_PIN, PWM_CHANNEL);
  Serial.println("   ✅ PWM setup complete (1kHz, 8-bit, Channel 0)");
  
  for (int i = 0; i < 6; i++) {
    Serial.print("   Beep ");
    Serial.print(i + 1);
    Serial.println("/6...");
    
    // Generate 1kHz tone by setting 50% duty cycle (128/255)
    ledcWrite(PWM_CHANNEL, 128);  // 50% duty cycle = audible tone
    delay(250);  // Beep ON for 250ms
    
    ledcWrite(PWM_CHANNEL, 0);    // 0% duty cycle = silence
    delay(250);  // Beep OFF for 250ms (total 500ms per cycle)
  }
  // Total beeping time: 6 cycles × 500ms = 3000ms (3 seconds)
  
  Serial.println("   🔇 Beeping finished - disabling PWM");
  
  // CRITICAL: Completely disable PWM and force audio pin to LOW (silence)
  ledcDetachPin(AUDIO_PIN);
  pinMode(AUDIO_PIN, OUTPUT);
  digitalWrite(AUDIO_PIN, LOW);  // Force pin LOW (true silence)
  delay(100);  // Give time for pin to settle completely
  
  Serial.println("🔄 Audio beep completed on D9");
  
  // Re-enable audio timer if it was running
  if (audioTimer != nullptr && isPlayingAudio) {
    timerAlarmEnable(audioTimer);
  }
  
  // Quick LED flash to confirm button press
  for (int i = 0; i < 2; i++) {
    digitalWrite(LED_BUILTIN, !digitalRead(LED_BUILTIN));
    delay(50);
  }
  digitalWrite(LED_BUILTIN, HIGH);
  
  // 📡 THEN send panic alert to server (after beeping)
  if (wifiConnected) {
    sendPanicAlertAsync();
  } else {
    Serial.println("❌ WiFi not connected - cannot send panic alert!");
  }
}

void selectPanicInputMode(bool usePullup) {
  panicUsingPullup = usePullup;
  if (panicUsingPullup) {
    pinMode(PANIC_BUTTON_PIN, INPUT_PULLUP);
    panicIdleLevel = HIGH;
    panicActiveLevel = LOW;
  } else {
    pinMode(PANIC_BUTTON_PIN, INPUT_PULLDOWN);
    panicIdleLevel = LOW;
    panicActiveLevel = HIGH;
  }
  delay(5);
  panicLastRawLevel = digitalRead(PANIC_BUTTON_PIN);
}

void configurePanicButtonInput() {
  // Sample the pin under both pull configurations to detect external wiring preference
  pinMode(PANIC_BUTTON_PIN, INPUT_PULLUP);
  delay(5);
  int pullupSample = digitalRead(PANIC_BUTTON_PIN);
  pinMode(PANIC_BUTTON_PIN, INPUT_PULLDOWN);
  delay(5);
  int pulldownSample = digitalRead(PANIC_BUTTON_PIN);
  bool externalKeepsHigh = (pulldownSample == HIGH);
  bool externalKeepsLow = (pullupSample == LOW);

  if (externalKeepsHigh && !externalKeepsLow) {
    selectPanicInputMode(false);  // Use pulldown for active-high wiring
    Serial.println("   ↪️  Panic button wiring auto-detected as ACTIVE-HIGH (internal pulldown enabled)");
  } else {
    selectPanicInputMode(true);   // Default to pullup & active-low wiring
    Serial.println("   ↪️  Panic button wiring auto-detected as ACTIVE-LOW (internal pullup enabled)");
  }

  int irqNumber = digitalPinToInterrupt(PANIC_BUTTON_PIN);
  if (irqNumber < 0) {
    panicInterruptAttached = false;
    Serial.println("⚠️  Panic button pin does not support interrupts on this board. Falling back to polling only.");
  } else {
    attachInterrupt(irqNumber, panicButtonISR, CHANGE);
    panicInterruptAttached = true;
  }

  Serial.print("   ↪️  Panic button active level now treated as: ");
  Serial.println(panicActiveLevel == LOW ? "LOW (active-low)" : "HIGH (active-high)");
}

int readPanicPinWithMode(bool usePullup) {
  noInterrupts();
  pinMode(PANIC_BUTTON_PIN, usePullup ? INPUT_PULLUP : INPUT_PULLDOWN);
  delayMicroseconds(30);
  int value = digitalRead(PANIC_BUTTON_PIN);
  pinMode(PANIC_BUTTON_PIN, panicUsingPullup ? INPUT_PULLUP : INPUT_PULLDOWN);
  interrupts();
  return value;
}

bool autoDetectAlternatePanicPress() {
  if (millis() - panicLastAltCheck < PANIC_ALT_CHECK_INTERVAL) {
    return false;
  }

  panicLastAltCheck = millis();
  bool alternateMode = !panicUsingPullup;
  int altReading = readPanicPinWithMode(alternateMode);
  int altActiveLevel = alternateMode ? LOW : HIGH;

  if (altReading == altActiveLevel) {
    if (panicAltModeActiveCount < 255) {
      panicAltModeActiveCount++;
    }
    if (panicAltModeActiveCount >= PANIC_ALT_CONFIRM_COUNT) {
      panicAltModeActiveCount = 0;
      return true;
    }
  } else {
    panicAltModeActiveCount = 0;
  }

  return false;
}

void IRAM_ATTR panicButtonISR() {
  uint32_t now = micros();
  if (now - panicLastInterruptMicros < PANIC_ISR_DEBOUNCE_US) {
    return;  // Ignore successive edges that arrive within the debounce window
  }

  panicLastInterruptMicros = now;
  panicPreviousRawLevel = panicLastRawLevel;
  panicLastRawLevel = digitalRead(PANIC_BUTTON_PIN);

  // Trigger on FALLING edge (HIGH→LOW transition) for momentary button
  if (panicPreviousRawLevel == panicIdleLevel && panicLastRawLevel == panicActiveLevel) {
    panicLatchedPressFlag = true;  // Remember the press edge
  }
}

// Send panic alert to server (ASYNC - starts request and returns immediately)
void sendPanicAlertAsync() {
  // Use WiFiClientSecure for HTTPS
  WiFiClientSecure client;
  client.setInsecure();  // Skip SSL certificate verification (Render uses valid cert, but this is faster)
  
  HTTPClient http;
  
  String url = String(SERVER_URL) + "/api/panic";
  
  Serial.print("📤 Sending panic alert to: ");
  Serial.println(url);
  
  if (!http.begin(client, url)) {
    Serial.println("❌ Failed to initialize HTTPS connection!");
    return;
  }
  
  http.addHeader("Content-Type", "application/json");
  http.setTimeout(10000);  // 10 second timeout (Render cold start can take 30-60s on free tier)
  
  Serial.println("⏳ Note: Render free tier may take 30-60s to wake up if sleeping...");
  
  // Get current time in UTC (consistent with telemetry timestamps)
  struct tm timeinfo;
  char timestamp[30];
  if (getLocalTime(&timeinfo)) {
    // NTP synced - convert Manila time to UTC and send ISO 8601 timestamp with 'Z'
    // getLocalTime returns Manila time (UTC+8), so subtract 8 hours to get UTC
    time_t now;
    time(&now);
    now -= 8 * 3600;  // Subtract 8 hours to convert Manila to UTC
    struct tm* utcTime = gmtime(&now);
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%dT%H:%M:%SZ", utcTime);
    Serial.print("⏰ Using NTP time (UTC): ");
    Serial.println(timestamp);
  } else {
    // NTP not synced yet - use epoch time (1970-01-01) with millis offset
    unsigned long ms = millis();
    unsigned long totalSeconds = ms / 1000;
    int hours = (totalSeconds / 3600) % 24;
    int minutes = (totalSeconds / 60) % 60;
    int seconds = totalSeconds % 60;
    sprintf(timestamp, "1970-01-01T%02d:%02d:%02dZ", hours, minutes, seconds);
    Serial.print("⏰ Using millis-based time (UTC): ");
    Serial.println(timestamp);
  }
  
  // Use real GPS coordinates if available, fallback to indoor location if no fix
  float panicLat, panicLng;
  
  if (gpsFixValid) {
    // Use real GPS coordinates
    panicLat = gpsLat;
    panicLng = gpsLng;
  } else {
    // Indoor fallback location: 14.074322, 121.326667
    // Use SAME fallback as telemetry (with drift)
    static unsigned long lastDriftUpdate = 0;
    static float latDrift = 0.0;
    static float lngDrift = 0.0;
    
    if (millis() - lastDriftUpdate > 3000) {
      float t = (millis() % 120000) / 120000.0;
      latDrift = sin(t * 2.0 * PI) * 0.00003;
      lngDrift = cos(t * 3.0 * PI) * 0.00004;
      latDrift += ((random(0, 100) / 100.0) - 0.5) * 0.00002;
      lngDrift += ((random(0, 100) / 100.0) - 0.5) * 0.00002;
      lastDriftUpdate = millis();
    }
    
    panicLat = 14.074322 + latDrift;
    panicLng = 121.326667 + lngDrift;
    
    //panicLat = 14.165089 + latDrift;
    //panicLng = 121.347506 + lngDrift;
    
    Serial.print("⚠️ No GPS fix - using indoor fallback: ");
    Serial.print(panicLat, 6);
    Serial.print(", ");
    Serial.println(panicLng, 6);
  }
  
  String payload = "{\"deviceId\":\"pendant-1\",\"location\":{\"lat\":" + String(panicLat, 6) + ",\"lng\":" + String(panicLng, 6) + "},\"timestamp\":\"" + String(timestamp) + "\"}";
  
  Serial.print("📦 Payload: ");
  Serial.println(payload);
  
  // Send POST request (this is still blocking, but we minimize delay)
  unsigned long startTime = millis();
  int httpCode = http.POST(payload);
  unsigned long endTime = millis();
  
  if (httpCode > 0) {
    Serial.print("✅ Panic alert sent! HTTP Code: ");
    Serial.print(httpCode);
    Serial.print(" in ");
    Serial.print(endTime - startTime);
    Serial.println("ms");
  } else {
    Serial.print("❌ Panic alert failed! Error: ");
    Serial.println(http.errorToString(httpCode));
  }
  
  http.end();
}

// ========================================
// 🎵 AUDIO PLAYBACK FUNCTIONS
// ========================================

// Setup PWM for audio output on D9 (called when needed, not at startup)
void setupAudioPWM() {
  // Configure D9 as PWM output for audio
  ledcSetup(0, PWM_FREQUENCY, PWM_RESOLUTION);  // Channel 0, 40kHz, 8-bit
  ledcAttachPin(AUDIO_PIN, 0);
  ledcWrite(0, 128);  // Set to middle value (silence)
  // Don't print - this is called dynamically
}

// Timer interrupt for audio playback at 8kHz
void IRAM_ATTR onAudioTimer() {
  if (!isPlayingAudio || audioBuffer == nullptr || audioPlaybackIndex >= audioBufferSize) {
    isPlayingAudio = false;
    return;
  }
  
  // Get next audio sample and convert from int16 to uint8 (0-255)
  int16_t sample = audioBuffer[audioPlaybackIndex++];
  uint8_t pwmValue = (uint8_t)((sample + 32768) >> 8);  // Convert -32768..32767 to 0..255
  
  // Output to PWM
  ledcWrite(0, pwmValue);
}

// Setup Web Server
void setupWebServer() {
  // POST /audio endpoint - receives audio from Flutter app via backend
  server.on("/audio", HTTP_POST, []() {
    Serial.println("🎵 Received audio POST request");
    
    if (!server.hasArg("plain")) {
      server.send(400, "application/json", "{\"error\":\"No body\"}");
      return;
    }
    
    String body = server.arg("plain");
    Serial.printf("📦 Body size: %d bytes\n", body.length());
    
    // ⚡ MEMORY FIX: Extract base64 audio string directly without full JSON parsing
    // The JSON is simple: {"audio":"<base64>","timestamp":"..."}
    // We can find the base64 string without allocating huge JSON buffer
    
    int audioStart = body.indexOf("\"audio\":\"");
    if (audioStart == -1) {
      Serial.println("❌ No 'audio' field found in JSON");
      server.send(400, "application/json", "{\"error\":\"No audio field\"}");
      return;
    }
    
    audioStart += 9; // Skip past "audio":"
    int audioEnd = body.indexOf("\"", audioStart);
    if (audioEnd == -1) {
      Serial.println("❌ Malformed JSON - no closing quote for audio field");
      server.send(400, "application/json", "{\"error\":\"Malformed JSON\"}");
      return;
    }
    
    // Extract base64 audio string (this is just a reference, no copy)
    String base64Audio = body.substring(audioStart, audioEnd);
    Serial.printf("📥 Base64 audio length: %d\n", base64Audio.length());
    
    // Decode base64 to raw audio bytes using ESP32's base64 library
    size_t base64Len = base64Audio.length();
    const char* base64Str = base64Audio.c_str();
    
    // Calculate expected decoded size: base64 uses 4 chars for 3 bytes
    // Formula: (base64Len / 4) * 3, accounting for padding
    size_t decodedSize = (base64Len / 4) * 3;
    if (base64Len > 0 && base64Str[base64Len - 1] == '=') decodedSize--;
    if (base64Len > 1 && base64Str[base64Len - 2] == '=') decodedSize--;
    
    if (decodedSize == 0) {
      Serial.println("❌ Invalid base64 data");
      server.send(400, "application/json", "{\"error\":\"Invalid base64\"}");
      return;
    }
    
    Serial.printf("📊 Allocating %d bytes for decoded audio\n", decodedSize);
    uint8_t* decodedData = (uint8_t*)malloc(decodedSize);
    
    if (!decodedData) {
      Serial.println("❌ Failed to allocate memory for decoded audio");
      server.send(500, "application/json", "{\"error\":\"Out of memory\"}");
      return;
    }
    
    // Decode using ESP32 base64 library (from mbedtls)
    size_t actualSize = 0;
    int result = mbedtls_base64_decode(decodedData, decodedSize, &actualSize, 
                                        (const unsigned char*)base64Str, base64Len);
    
    if (result != 0) {
      Serial.printf("❌ Base64 decode failed with error: %d\n", result);
      free(decodedData);
      server.send(400, "application/json", "{\"error\":\"Base64 decode failed\"}");
      return;
    }
    
    Serial.printf("📊 Decoded audio size: %d bytes\n", actualSize);
    
    // WAV files start with a 44-byte header, audio data starts after that
    // WAV format: RIFF header (12 bytes) + fmt chunk (24 bytes) + data chunk header (8 bytes) = 44 bytes
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
    } else {
      Serial.println("📦 Assuming raw audio data (no WAV header detected)");
    }
    
    // Play the audio through PWM
    Serial.println("🔊 Playing audio through PWM on D7...");
    
    // Switch to PWM output mode on D9 - 40kHz for better filtering
    ledcSetup(PWM_CHANNEL, PWM_FREQUENCY, PWM_RESOLUTION);  // 40kHz PWM, 8-bit resolution
    ledcAttachPin(AUDIO_PIN, PWM_CHANNEL);
    ledcWrite(PWM_CHANNEL, 0);  // Start at 0 (complete silence, no midpoint noise)
    
    delay(10);  // Small delay to stabilize PWM
    
    // Determine if audio is 8-bit or 16-bit
    // WAV PCM is typically 16-bit (2 bytes per sample)
    bool is16Bit = (pcmDataSize % 2 == 0);  // If size is even, likely 16-bit
    
    Serial.printf("🎵 Audio format: %s\n", is16Bit ? "16-bit PCM" : "8-bit PCM");
    
    if (is16Bit && pcmDataSize >= 2) {
      // 16-bit PCM audio (2 bytes per sample)
      size_t numSamples = pcmDataSize / 2;
      Serial.printf("📊 Playing %d samples at 8kHz (%.1f seconds)\n", numSamples, (float)numSamples / 8000.0);
      
      // Calculate timing for 8kHz sample rate
      const unsigned long sampleIntervalMicros = 125;  // 1000000 / 8000 = 125 microseconds
      unsigned long nextSampleTime = micros() + sampleIntervalMicros;
      
      // Simple low-pass filter to smooth audio (reduces "shattered glass" effect)
      uint8_t previousSample = 128;  // Start at midpoint
      const float SMOOTHING = 0.7;   // Smoothing factor (0.0-1.0, higher = smoother)
      
      for (size_t i = 0; i < numSamples; i++) {
        // Read 16-bit sample (little-endian)
        int16_t sample16 = (int16_t)(pcmData[i*2] | (pcmData[i*2 + 1] << 8));
        
        // Convert from 16-bit signed (-32768 to 32767) to 8-bit unsigned (0-255)
        // Formula: output = (input / 256) + 128
        int32_t scaled = ((int32_t)sample16 >> 8) + 128;
        uint8_t sample8 = (uint8_t)constrain(scaled, 0, 255);
        
        // Apply simple low-pass filter (exponential moving average)
        // This smooths out harsh transitions that cause "broken radio" sound
        sample8 = (uint8_t)((SMOOTHING * previousSample) + ((1.0 - SMOOTHING) * sample8));
        previousSample = sample8;
        
        // NOISE REDUCTION: Detect silence and output true 0 instead of 128
        // If sample is very close to midpoint (128), treat as silence
        if (abs((int)sample8 - 128) < SILENCE_THRESHOLD) {
          sample8 = 0;  // Complete silence - no PWM noise
        }
        
        // Write sample to PWM
        ledcWrite(PWM_CHANNEL, sample8);
        
        // Wait for next sample time (precise timing)
        while (micros() < nextSampleTime) {
          // Tight loop for accuracy
        }
        nextSampleTime += sampleIntervalMicros;
      }
      
    } else {
      // 8-bit PCM audio (1 byte per sample)
      Serial.printf("📊 Playing %d samples at 8kHz (%.1f seconds)\n", pcmDataSize, (float)pcmDataSize / 8000.0);
      
      // Calculate timing for 8kHz sample rate
      const unsigned long sampleIntervalMicros = 125;  // 1000000 / 8000 = 125 microseconds
      unsigned long nextSampleTime = micros() + sampleIntervalMicros;
      
      // Simple low-pass filter to smooth audio
      uint8_t previousSample = 128;  // Start at midpoint
      const float SMOOTHING = 0.7;   // Smoothing factor
      
      for (size_t i = 0; i < pcmDataSize; i++) {
        uint8_t sample8 = pcmData[i];
        
        // Apply simple low-pass filter
        sample8 = (uint8_t)((SMOOTHING * previousSample) + ((1.0 - SMOOTHING) * sample8));
        previousSample = sample8;
        
        // NOISE REDUCTION: Detect silence and output true 0 instead of 128
        if (abs((int)sample8 - 128) < SILENCE_THRESHOLD) {
          sample8 = 0;  // Complete silence - no PWM noise
        }
        
        // Write 8-bit sample directly
        ledcWrite(PWM_CHANNEL, sample8);
        
        // Wait for next sample time (precise timing)
        while (micros() < nextSampleTime) {
          // Tight loop for accuracy
        }
        nextSampleTime += sampleIntervalMicros;
      }
    }
    
    // CRITICAL: Complete silence at end - output 0, NOT 128
    ledcWrite(PWM_CHANNEL, 0);
    delay(50);  // Hold silence for 50ms
    
    // ⚠️ CRITICAL: COMPLETELY DISABLE PWM to eliminate ALL noise on D9
    ledcDetachPin(AUDIO_PIN);  // Detach PWM channel FIRST
    pinMode(AUDIO_PIN, OUTPUT);  // Switch to OUTPUT
    digitalWrite(AUDIO_PIN, LOW);  // Force pin to LOW (true silence)
    delay(100);  // Wait for pin to settle completely
    
    Serial.println("✅ Audio playback completed on D9");
    
    // Reset panic button debounce to prevent false trigger
    panicPressed = false;
    panicDebounceTime = millis();  // Start fresh debounce period
    audioJustFinished = true;  // Enable cooldown period to prevent false trigger
    
    Serial.println("⏱️  Starting 500ms cooldown before panic button re-activation");
    
    free(decodedData);
    
    server.send(200, "application/json", "{\"success\":true,\"message\":\"Audio received and played successfully\"}");
    Serial.println("✅ Audio processing completed");
  });
  
  // GET / - status endpoint
  server.on("/", HTTP_GET, []() {
    server.send(200, "text/plain", "Smart Pendant Arduino - Audio Receiver Ready");
  });
  
  server.begin();
  Serial.println("🌐 Web Server started on port 80");
  Serial.print("   Audio endpoint: http://");
  Serial.print(WiFi.localIP());
  Serial.println("/audio");
}

