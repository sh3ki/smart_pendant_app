/*
 * Comprehensive I2C Scanner with Pull-up Detection
 * Tests I2C bus health and scans for all devices
 */

#include <Wire.h>

#define SDA_PIN 18  // A4
#define SCL_PIN 19  // A5

void setup() {
  Serial.begin(115200);
  delay(2000);
  
  Serial.println("\n╔═══════════════════════════════════════════╗");
  Serial.println("║  Comprehensive I2C Diagnostics          ║");
  Serial.println("╚═══════════════════════════════════════════╝\n");
  
  // Test 1: Pin voltage check
  Serial.println("📊 TEST 1: Pin Voltage Check");
  pinMode(SDA_PIN, INPUT);
  pinMode(SCL_PIN, INPUT);
  delay(10);
  
  int sdaState = digitalRead(SDA_PIN);
  int sclState = digitalRead(SCL_PIN);
  
  Serial.print("  SDA (A4/GPIO18): ");
  Serial.println(sdaState ? "HIGH (pulled up ✅)" : "LOW (no pull-up ❌)");
  Serial.print("  SCL (A5/GPIO19): ");
  Serial.println(sclState ? "HIGH (pulled up ✅)" : "LOW (no pull-up ❌)");
  
  if (sdaState == LOW || sclState == LOW) {
    Serial.println("\n⚠️  WARNING: Missing pull-up resistors!");
    Serial.println("   Solution: Add 4.7kΩ resistors from SDA/SCL to 3.3V");
  }
  Serial.println();
  
  // Test 2: Initialize I2C
  Serial.println("📊 TEST 2: I2C Bus Initialization");
  Wire.begin(SDA_PIN, SCL_PIN);
  Wire.setClock(100000);  // 100kHz (standard mode)
  Serial.println("  ✅ I2C initialized at 100kHz");
  Serial.println();
  
  // Test 3: Full I2C scan
  Serial.println("📊 TEST 3: Complete I2C Address Scan (0x01-0x7F)");
  Serial.println("  Scanning...\n");
  
  int deviceCount = 0;
  for (byte addr = 1; addr < 127; addr++) {
    Wire.beginTransmission(addr);
    byte error = Wire.endTransmission();
    
    if (error == 0) {
      Serial.print("  ✅ Device found at 0x");
      if (addr < 16) Serial.print("0");
      Serial.print(addr, HEX);
      Serial.print(" (");
      Serial.print(addr);
      Serial.print(")");
      
      // Identify known devices
      if (addr == 0x21) Serial.print(" ← OV7670 (Write)");
      if (addr == 0x42) Serial.print(" ← OV7670 (Read)");
      if (addr == 0x53) Serial.print(" ← ADXL345");
      if (addr == 0x60) Serial.print(" ← OV7670 Alt");
      if (addr == 0x61) Serial.print(" ← OV7670 Alt");
      if (addr == 0x30) Serial.print(" ← OV7670 Alt");
      
      Serial.println();
      deviceCount++;
    }
    
    delay(1);
  }
  
  Serial.println();
  Serial.print("  Total devices found: ");
  Serial.println(deviceCount);
  
  if (deviceCount == 0) {
    Serial.println("\n❌ NO DEVICES FOUND!");
    Serial.println("   Possible causes:");
    Serial.println("   1. No pull-up resistors on SDA/SCL");
    Serial.println("   2. Camera not powered");
    Serial.println("   3. Wrong SDA/SCL connections");
    Serial.println("   4. Camera doesn't use I2C (serial interface only)");
  }
  Serial.println();
  
  // Test 4: Check specific OV7670 addresses with detailed errors
  Serial.println("📊 TEST 4: OV7670 Specific Address Test");
  byte ov7670_addresses[] = {0x21, 0x42, 0x30, 0x60, 0x61};
  
  for (int i = 0; i < 5; i++) {
    byte addr = ov7670_addresses[i];
    Serial.print("  Testing 0x");
    if (addr < 16) Serial.print("0");
    Serial.print(addr, HEX);
    Serial.print(": ");
    
    Wire.beginTransmission(addr);
    byte error = Wire.endTransmission();
    
    switch (error) {
      case 0:
        Serial.println("✅ ACK received (device present!)");
        break;
      case 2:
        Serial.println("❌ NACK on address (no device)");
        break;
      case 3:
        Serial.println("❌ NACK on data");
        break;
      case 4:
        Serial.println("❌ Other error");
        break;
      case 5:
        Serial.println("❌ Timeout");
        break;
      default:
        Serial.print("❌ Unknown error: ");
        Serial.println(error);
    }
    delay(10);
  }
  
  Serial.println("\n╔═══════════════════════════════════════════╗");
  Serial.println("║  Diagnostic Complete                     ║");
  Serial.println("╚═══════════════════════════════════════════╝\n");
  
  Serial.println("📋 NEXT STEPS:");
  Serial.println("1. Check which devices were found");
  Serial.println("2. Verify pull-up resistor status");
  Serial.println("3. If no camera found, check:");
  Serial.println("   - Physical wiring (SDA/SCL connections)");
  Serial.println("   - Camera chip marking (is it really OV7670?)");
  Serial.println("   - Module type (I2C-capable or serial-only?)");
  Serial.println();
}

void loop() {
  // Nothing - run once
}
