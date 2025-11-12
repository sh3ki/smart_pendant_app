/*
 * Smart Pendant - Arduino Nano ESP32 Firmware with OV7670 Camera
 * 5 FPS Video Streaming to Backend Server
 * 
 * Components:
 * - GPS (Quectel L80) on Serial1 (D4=TX, D5=RX)
 * - ADXL345 accelerometer on I2C (A4=SDA, A5=SCL)
 * - OV7670 camera on parallel interface (D6,D8-D9,D11-D13,A0-A3,B0-B1)
 * - Panic button + Audio on D7 (SHARED PIN!)
 */

#include <WiFi.h>
#include <HTTPClient.h>
#include <Wire.h>
#include <base64.h>  // Use Arduino's built-in base64 library

// ========================================
// 🔧 CONFIGURATION
// ========================================
const char* WIFI_SSID = "wifi";
const char* WIFI_PASSWORD = "12345678";
const char* SERVER_URL = "http://192.168.224.11:3000";

// ========================================
// 🔌 PIN DEFINITIONS
// ========================================
// Panic Button + Audio (SHARED!)
#define PANIC_AUDIO_PIN   7   // D7 (shared between button input and audio output)

// I2C Pins
#define SDA_PIN A4  // A4 = GPIO18 on Nano ESP32
#define SCL_PIN A5  // A5 = GPIO19 on Nano ESP32

// GPS Serial
#define GPS_RX_PIN 5
#define GPS_TX_PIN 4

// OV7670 Camera Pins
#define CAM_MCLK   9   // Master clock (PWM)
#define CAM_PCLK   8   // Pixel clock
#define CAM_VS     6   // Vertical sync (frame start)
#define CAM_HS     11  // Horizontal sync (line valid)
#define CAM_D0     12  // Data bit 0
#define CAM_D1     13  // Data bit 1
#define CAM_D2     A0  // Data bit 2
#define CAM_D3     A1  // Data bit 3
#define CAM_D4     A2  // Data bit 4
#define CAM_D5     A3  // Data bit 5
#define CAM_D6     B0  // Data bit 6
#define CAM_D7     B1  // Data bit 7
#define CAM_RESET  10  // Reset pin (active LOW) - D10 available
#define CAM_PWDN   A6  // Power-down pin (active HIGH) - A6 available

// ========================================
// 🌍 ADXL345 REGISTERS
// ========================================
#define ADXL345_ADDRESS   0x53
#define ADXL345_POWER_CTL 0x2D
#define ADXL345_DATAX0    0x32

// ========================================
// 📷 OV7670 SETTINGS
// ========================================
#define OV7670_ADDRESS    0x21  // I2C address for configuration
#define IMAGE_WIDTH       160   // QQVGA width
#define IMAGE_HEIGHT      120   // QQVGA height
#define IMAGE_SIZE        (IMAGE_WIDTH * IMAGE_HEIGHT / 8) // 1 bit per pixel (grayscale threshold)

// ========================================
// 📊 GLOBAL VARIABLES
// ========================================
bool wifiConnected = false;
bool panicPressed = false;
unsigned long lastTelemetrySend = 0;
unsigned long lastImageCapture = 0;
const unsigned long TELEMETRY_INTERVAL = 5000;  // 5 seconds
const unsigned long IMAGE_INTERVAL = 200;       // 200ms = 5 FPS

// Telemetry data
float accelX = 0.0, accelY = 0.0, accelZ = 0.0;
float gpsLat = 37.774851, gpsLng = -122.419388;
float gpsSpeed = 0.0;
int batteryPercent = 75;
String activityType = "IDLE";
uint32_t frameNumber = 0;

// Image buffer (small for memory constraints)
uint8_t imageBuffer[IMAGE_SIZE];
bool cameraInitialized = false;
byte cameraI2CAddress = OV7670_ADDRESS;  // Store detected camera address

// ========================================
// ⚙️ SETUP
// ========================================
void setup() {
  Serial.begin(115200);
  delay(2000);
  
  Serial.println("\n╔════════════════════════════════════════╗");
  Serial.println("║  🚀 Smart Pendant with Camera        ║");
  Serial.println("║     5 FPS Video Streaming            ║");
  Serial.println("╚════════════════════════════════════════╝\n");

  // Initialize shared panic/audio pin as INPUT
  pinMode(PANIC_AUDIO_PIN, INPUT_PULLUP);
  pinMode(LED_BUILTIN, OUTPUT);
  
  // Initialize I2C
  Wire.begin(SDA_PIN, SCL_PIN);
  
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
      if (addr == 0x21) Serial.print(" (OV7670)");
      Serial.println();
      deviceCount++;
    }
  }
  Serial.print("  Total devices found: ");
  Serial.println(deviceCount);
  Serial.println();
  
  initADXL345();
  
  // Initialize camera
  initOV7670();
  Serial.print("Camera initialized: ");
  Serial.println(cameraInitialized ? "YES" : "NO");
  
  // Initialize GPS
  Serial1.begin(9600, SERIAL_8N1, GPS_RX_PIN, GPS_TX_PIN);
  Serial.println("📡 GPS Serial initialized");
  
  // Connect to WiFi
  connectWiFi();
  
  Serial.println("\n✅ Setup complete! Starting main loop...\n");
}

// ========================================
// 🔄 MAIN LOOP
// ========================================
void loop() {
  // Check WiFi
  if (WiFi.status() != WL_CONNECTED) {
    wifiConnected = false;
    connectWiFi();
    return;
  }
  wifiConnected = true;
  
  // Read sensors
  readADXL345();
  readGPS();
  detectActivity();
  
  // Check panic button (pin is INPUT_PULLUP)
  if (digitalRead(PANIC_AUDIO_PIN) == LOW) {
    if (!panicPressed) {
      panicPressed = true;
      handlePanicButton();
      delay(1000);
    }
  } else {
    panicPressed = false;
  }
  
  // Capture and send image (5 FPS)
  if (cameraInitialized && millis() - lastImageCapture >= IMAGE_INTERVAL) {
    captureAndSendImage();
    lastImageCapture = millis();
  } else if (!cameraInitialized && millis() - lastImageCapture >= IMAGE_INTERVAL) {
    // Debug: Camera not initialized
    static unsigned long lastCameraWarning = 0;
    if (millis() - lastCameraWarning >= 10000) { // Every 10 seconds
      Serial.println("⚠️ Camera not initialized - skipping frame capture");
      lastCameraWarning = millis();
    }
    lastImageCapture = millis();
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
  Wire.requestFrom(ADXL345_ADDRESS, 6, true);
  
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
// 📷 OV7670 INITIALIZATION
// ========================================
void initOV7670() {
  Serial.println("📷 Initializing OV7670 camera...");
  Serial.println("   ⚠️  Camera MUST have 3.3V power (NOT 5V!)");
  
  // ========================================
  // STEP 1: Hardware Power-On Sequence
  // ========================================
  Serial.println("   🔌 Step 1: Hardware power-on sequence");
  
  // Configure control pins
  pinMode(CAM_RESET, OUTPUT);
  pinMode(CAM_PWDN, OUTPUT);
  
  // Power-down sequence (wake up camera)
  digitalWrite(CAM_PWDN, HIGH);  // Enter power-down
  delay(10);
  digitalWrite(CAM_PWDN, LOW);   // Exit power-down (camera ON)
  delay(10);
  
  // Reset sequence
  digitalWrite(CAM_RESET, LOW);  // Assert reset
  delay(10);
  digitalWrite(CAM_RESET, HIGH); // De-assert reset
  delay(100);                    // Wait for camera to initialize
  
  Serial.println("      ✅ RESET released, PWDN disabled");
  
  // ========================================
  // STEP 2: Configure GPIO pins
  // ========================================
  Serial.println("   📌 Step 2: Configuring data/sync pins");
  
  // Configure camera data pins as inputs
  pinMode(CAM_D0, INPUT);
  pinMode(CAM_D1, INPUT);
  pinMode(CAM_D2, INPUT);
  pinMode(CAM_D3, INPUT);
  pinMode(CAM_D4, INPUT);
  pinMode(CAM_D5, INPUT);
  pinMode(CAM_D6, INPUT);
  pinMode(CAM_D7, INPUT);
  
  // Configure sync pins as inputs
  pinMode(CAM_PCLK, INPUT);
  pinMode(CAM_VS, INPUT);
  pinMode(CAM_HS, INPUT);
  
  // ========================================
  // STEP 3: Generate Master Clock (MCLK)
  // ========================================
  Serial.println("   🔄 Step 3: Starting MCLK (10 MHz)");
  
  // Configure MCLK as PWM output (10 MHz clock for camera)
  ledcSetup(0, 10000000, 8); // Channel 0, 10MHz, 8-bit resolution
  ledcAttachPin(CAM_MCLK, 0);
  ledcWrite(0, 128); // 50% duty cycle
  
  delay(100); // Wait for camera to stabilize with clock
  Serial.println("      ✅ MCLK running");
  
  // ========================================
  // STEP 4: Check if camera is generating signals
  // ========================================
  Serial.println("   🔍 Step 4: Checking camera output signals");
  delay(50);
  
  int vsState = digitalRead(CAM_VS);
  int hsState = digitalRead(CAM_HS);
  int pclkState = digitalRead(CAM_PCLK);
  
  Serial.print("      VS=");
  Serial.print(vsState ? "HIGH" : "LOW");
  Serial.print(" HS=");
  Serial.print(hsState ? "HIGH" : "LOW");
  Serial.print(" PCLK=");
  Serial.println(pclkState ? "HIGH" : "LOW");
  
  // Check if we have VS signal (required for frame sync)
  if (vsState) {
    Serial.println("      ✅ VS signal detected - camera ready!");
    Serial.println("      🎉 Camera working WITHOUT I2C config!");
    Serial.println("      ℹ️  Will use factory default settings");
    cameraInitialized = true;
    Serial.println("\n✅ Camera enabled in parallel mode (factory defaults)");
    return;
  }
  
  // Check if any other signals are present
  if (hsState || pclkState) {
    Serial.println("      ⚠️  HS/PCLK signals present but VS missing");
    Serial.println("      ℹ️  Camera may need I2C config to enable VS");
  } else {
    Serial.println("      ⚠️  Camera signals still LOW (may need I2C config)");
  }
  
  // ========================================
  // STEP 5: Try I2C detection and configuration
  // ========================================
  Serial.println("   🔍 Step 5: Attempting I2C detection");
  
  delay(100); // Wait for camera to stabilize
  
  // Try to detect camera via I2C (try multiple addresses)
  byte detectedAddress = 0;
  byte addresses[] = {0x21, 0x42, 0x43, 0x30, 0x60, 0x61, 0x20, 0x40, 0x41};
  
  Serial.print("      Trying addresses: ");
  for (int i = 0; i < 9; i++) {
    Wire.beginTransmission(addresses[i]);
    byte error = Wire.endTransmission();
    
    Serial.print("0x");
    if (addresses[i] < 16) Serial.print("0");
    Serial.print(addresses[i], HEX);
    Serial.print(" ");
    
    if (error == 0) {
      detectedAddress = addresses[i];
      break;
    }
  }
  Serial.println();
  
  if (detectedAddress > 0) {
    Serial.print("      ✅ I2C OK (Found at 0x");
    Serial.print(detectedAddress, HEX);
    Serial.println(")");
    cameraInitialized = true;
    cameraI2CAddress = detectedAddress;  // Store the detected address
    
    // Configure camera for QQVGA (160x120) grayscale
    Serial.println("   ⚙️  Step 6: Configuring QQVGA resolution");
    configureCameraQQVGA();
  } else {
    Serial.println("      ❌ Not detected on I2C bus");
    Serial.println("      ⚠️  Attempting FORCED I2C configuration (no ACK)");
    Serial.println("      ℹ️  Some cameras accept I2C writes without ACK");
    
    // Force configuration anyway - camera might still receive data
    cameraI2CAddress = 0x21;  // Use default write address
    configureCameraQQVGA();    // Try to configure anyway
    
    delay(200);  // Wait for camera to process
    
    // Check if signals appeared after forced config
    int vsState2 = digitalRead(CAM_VS);
    int hsState2 = digitalRead(CAM_HS);
    int pclkState2 = digitalRead(CAM_PCLK);
    
    Serial.print("      After forced config: VS=");
    Serial.print(vsState2 ? "HIGH" : "LOW");
    Serial.print(" HS=");
    Serial.print(hsState2 ? "HIGH" : "LOW");
    Serial.print(" PCLK=");
    Serial.println(pclkState2 ? "HIGH" : "LOW");
    
    if (vsState2 || hsState2 || pclkState2) {
      Serial.println("      ✅ SUCCESS! Camera responding after forced config!");
      cameraInitialized = true;
    } else {
      Serial.println("      ❌ FAILED: Camera not responding to I2C");
      Serial.println("      ⚠️  Camera module may be incompatible/defective");
      cameraInitialized = false;  // Don't try to capture
    }
  }
}

// ========================================
// 📷 CONFIGURE CAMERA FOR QQVGA
// ========================================
void configureCameraQQVGA() {
  // Basic OV7670 register configuration for QQVGA grayscale
  // This is a simplified version - full config would be much longer
  
  writeOV7670Reg(0x12, 0x80); // Reset camera
  delay(100);
  
  writeOV7670Reg(0x12, 0x14); // QQVGA + RGB mode
  writeOV7670Reg(0x11, 0x01); // Prescaler = 2 (reduce clock)
  writeOV7670Reg(0x0C, 0x04); // DCW enable
  writeOV7670Reg(0x3E, 0x1A); // Divider
  writeOV7670Reg(0x70, 0x3A); // X scaling
  writeOV7670Reg(0x71, 0x35); // Y scaling
  writeOV7670Reg(0x72, 0x11); // Downsample by 2
  writeOV7670Reg(0x73, 0xF1); // Divider
  
  Serial.println("📷 Camera configured for QQVGA");
}

void writeOV7670Reg(uint8_t reg, uint8_t value) {
  Wire.beginTransmission(cameraI2CAddress);  // Use detected address
  Wire.write(reg);
  Wire.write(value);
  Wire.endTransmission();
  delay(1);
}

// ========================================
// 📷 CAPTURE IMAGE
// ========================================
void captureAndSendImage() {
  if (!wifiConnected || !cameraInitialized) return;
  
  // Debug: Check camera signals
  static unsigned long lastDebug = 0;
  if (millis() - lastDebug > 5000) { // Every 5 seconds
    Serial.print("📷 Camera signals: VS=");
    Serial.print(digitalRead(CAM_VS) ? "HIGH" : "LOW");
    Serial.print(" HS=");
    Serial.print(digitalRead(CAM_HS) ? "HIGH" : "LOW");
    Serial.print(" PCLK=");
    Serial.println(digitalRead(CAM_PCLK) ? "HIGH" : "LOW");
    lastDebug = millis();
  }
  
  // Wait for new frame (VS goes HIGH)
  unsigned long timeout = millis();
  while (digitalRead(CAM_VS) == LOW) {
    if (millis() - timeout > 100) {
      Serial.println("⚠️ Timeout: VS signal not detected (camera not generating frames)");
      return; // Timeout
    }
  }
  while (digitalRead(CAM_VS) == HIGH) {
    if (millis() - timeout > 100) {
      Serial.println("⚠️ Timeout: VS signal stuck HIGH");
      return;
    }
  }
  
  // Capture frame data
  int pixelIndex = 0;
  for (int y = 0; y < IMAGE_HEIGHT && pixelIndex < IMAGE_SIZE * 8; y++) {
    // Wait for line start (HS goes HIGH)
    timeout = millis();
    while (digitalRead(CAM_HS) == LOW) {
      if (millis() - timeout > 10) break;
    }
    
    // Read pixels in this line
    for (int x = 0; x < IMAGE_WIDTH; x++) {
      // Wait for pixel clock
      while (digitalRead(CAM_PCLK) == LOW);
      
      // Read 8-bit pixel data
      uint8_t pixel = 0;
      pixel |= (digitalRead(CAM_D0) << 0);
      pixel |= (digitalRead(CAM_D1) << 1);
      pixel |= (digitalRead(CAM_D2) << 2);
      pixel |= (digitalRead(CAM_D3) << 3);
      pixel |= (digitalRead(CAM_D4) << 4);
      pixel |= (digitalRead(CAM_D5) << 5);
      pixel |= (digitalRead(CAM_D6) << 6);
      pixel |= (digitalRead(CAM_D7) << 7);
      
      // Store as 1-bit (threshold at 128)
      if (pixel > 128) {
        imageBuffer[pixelIndex / 8] |= (1 << (pixelIndex % 8));
      } else {
        imageBuffer[pixelIndex / 8] &= ~(1 << (pixelIndex % 8));
      }
      pixelIndex++;
      
      while (digitalRead(CAM_PCLK) == HIGH);
    }
  }
  
  // Send image to server
  sendImageToServer();
  frameNumber++;
}

// ========================================
// 📤 SEND IMAGE TO SERVER
// ========================================
void sendImageToServer() {
  HTTPClient http;
  String url = String(SERVER_URL) + "/api/image";
  
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  
  // Encode image as base64
  String base64Image = base64::encode(imageBuffer, IMAGE_SIZE);
  
  // Build JSON
  String payload = "{";
  payload += "\"deviceId\":\"pendant-1\",";
  payload += "\"frameNumber\":" + String(frameNumber) + ",";
  payload += "\"width\":" + String(IMAGE_WIDTH) + ",";
  payload += "\"height\":" + String(IMAGE_HEIGHT) + ",";
  payload += "\"format\":\"grayscale-1bit\",";
  payload += "\"timestamp\":\"" + String(millis()) + "\",";
  payload += "\"imageData\":\"" + base64Image + "\"";
  payload += "}";
  
  int httpCode = http.POST(payload);
  
  if (httpCode > 0) {
    Serial.print("📷 Frame ");
    Serial.print(frameNumber);
    Serial.print(" sent: ");
    Serial.println(httpCode);
  } else {
    Serial.print("❌ Image upload failed: ");
    Serial.println(http.errorToString(httpCode));
  }
  
  http.end();
}

// ========================================
// 🌍 GPS FUNCTIONS
// ========================================
void readGPS() {
  while (Serial1.available()) {
    String gpsData = Serial1.readStringUntil('\n');
    if (gpsData.startsWith("$GPGGA") || gpsData.startsWith("$GNGGA")) {
      parseGPGGA(gpsData);
    }
    if (gpsData.startsWith("$GPRMC") || gpsData.startsWith("$GNRMC")) {
      parseGPRMC(gpsData);
    }
  }
}

void parseGPGGA(String sentence) {
  // Same as before - simplified for space
  int commaPos[15];
  int commaCount = 0;
  for (int i = 0; i < sentence.length() && commaCount < 15; i++) {
    if (sentence.charAt(i) == ',') commaPos[commaCount++] = i;
  }
  if (commaCount >= 6) {
    String latStr = sentence.substring(commaPos[1] + 1, commaPos[2]);
    String lngStr = sentence.substring(commaPos[3] + 1, commaPos[4]);
    if (latStr.length() > 0 && lngStr.length() > 0) {
      float lat = latStr.toFloat();
      gpsLat = (int)(lat / 100) + (lat - (int)(lat / 100) * 100) / 60.0;
      float lng = lngStr.toFloat();
      gpsLng = (int)(lng / 100) + (lng - (int)(lng / 100) * 100) / 60.0;
    }
  }
}

void parseGPRMC(String sentence) {
  int commaPos[15];
  int commaCount = 0;
  for (int i = 0; i < sentence.length() && commaCount < 15; i++) {
    if (sentence.charAt(i) == ',') commaPos[commaCount++] = i;
  }
  if (commaCount >= 7) {
    String speedStr = sentence.substring(commaPos[6] + 1, commaPos[7]);
    if (speedStr.length() > 0) {
      gpsSpeed = speedStr.toFloat() * 0.514444;
    }
  }
}

// ========================================
// 🏃 ACTIVITY DETECTION
// ========================================
void detectActivity() {
  float magnitude = sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ);
  if (magnitude < 0.5) activityType = "IDLE";
  else if (magnitude < 1.5) activityType = "WALK";
  else if (magnitude < 2.5) activityType = "RUN";
  else activityType = "ACTIVE";
}

// ========================================
// 📤 SEND TELEMETRY
// ========================================
void sendTelemetry() {
  if (!wifiConnected) return;
  
  HTTPClient http;
  String url = String(SERVER_URL) + "/api/telemetry";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  
  String payload = "{";
  payload += "\"deviceId\":\"pendant-1\",";
  payload += "\"battery\":" + String(batteryPercent) + ",";
  payload += "\"location\":{\"lat\":" + String(gpsLat, 6) + ",\"lng\":" + String(gpsLng, 6) + ",\"accuracy\":13.1,\"speed\":" + String(gpsSpeed, 2) + "},";
  payload += "\"activity\":{\"type\":\"" + activityType + "\",\"steps\":1234,\"calories\":56},";
  payload += "\"accelerometer\":{\"x\":" + String(accelX, 3) + ",\"y\":" + String(accelY, 3) + ",\"z\":" + String(accelZ, 3) + "}";
  payload += "}";
  
  int httpCode = http.POST(payload);
  if (httpCode > 0) {
    Serial.print("📤 Telemetry: ");
    Serial.print(httpCode);
    Serial.print(" | Activity: ");
    Serial.println(activityType);
  }
  http.end();
}

// ========================================
// 🚨 PANIC BUTTON HANDLER
// ========================================
void handlePanicButton() {
  Serial.println("\n🚨🚨🚨 PANIC BUTTON PRESSED! 🚨🚨🚨\n");
  
  // Switch pin to OUTPUT mode for audio
  pinMode(PANIC_AUDIO_PIN, OUTPUT);
  tone(PANIC_AUDIO_PIN, 1000, 500); // 1kHz beep for 500ms
  delay(500);
  
  // Switch pin back to INPUT_PULLUP for button
  pinMode(PANIC_AUDIO_PIN, INPUT_PULLUP);
  
  // Send panic alert
  if (!wifiConnected) return;
  
  HTTPClient http;
  String url = String(SERVER_URL) + "/api/panic";
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  
  String payload = "{\"deviceId\":\"pendant-1\",\"location\":{\"lat\":" + String(gpsLat, 6) + ",\"lng\":" + String(gpsLng, 6) + "}}";
  int httpCode = http.POST(payload);
  
  if (httpCode > 0) {
    Serial.println("✅ Panic alert sent!");
    for (int i = 0; i < 10; i++) {
      digitalWrite(LED_BUILTIN, !digitalRead(LED_BUILTIN));
      delay(100);
    }
    digitalWrite(LED_BUILTIN, HIGH);
  }
  http.end();
}
