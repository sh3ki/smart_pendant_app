/*
 * OV7670 I2C Test Sketch
 * Tests if camera responds on I2C bus
 */

#include <Wire.h>

#define SDA_PIN 18  // A4 on Nano ESP32
#define SCL_PIN 19  // A5 on Nano ESP32

void setup() {
  Serial.begin(115200);
  delay(2000);
  
  Serial.println("\n╔════════════════════════════════╗");
  Serial.println("║  OV7670 I2C Detection Test   ║");
  Serial.println("╚════════════════════════════════╝\n");
  
  Wire.begin(SDA_PIN, SCL_PIN);
  delay(100);
  
  // Scan entire I2C bus
  Serial.println("🔍 Scanning I2C bus (0x01 to 0x7F)...\n");
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
      
      Serial.println();
      deviceCount++;
    }
    
    delay(1);
  }
  
  Serial.println();
  Serial.print("Total devices found: ");
  Serial.println(deviceCount);
  Serial.println();
  
  // Test specific OV7670 addresses
  Serial.println("🎯 Testing OV7670 specific addresses:\n");
  
  testAddress(0x21, "OV7670 Write Address");
  testAddress(0x42, "OV7670 Read Address");
  testAddress(0x60, "OV7670 Alt Address 1");
  testAddress(0x61, "OV7670 Alt Address 2");
  
  Serial.println("\n✅ Test complete!");
  Serial.println("\nIf no OV7670 addresses responded:");
  Serial.println("1. Check SDA/SCL wiring to camera");
  Serial.println("2. Verify camera has power (3.3V)");
  Serial.println("3. Check if SIOC/SIOD pins are connected");
}

void testAddress(byte addr, const char* name) {
  Serial.print("  Testing 0x");
  if (addr < 16) Serial.print("0");
  Serial.print(addr, HEX);
  Serial.print(" (");
  Serial.print(name);
  Serial.print(")... ");
  
  Wire.beginTransmission(addr);
  byte error = Wire.endTransmission();
  
  if (error == 0) {
    Serial.println("✅ FOUND!");
  } else if (error == 2) {
    Serial.println("❌ NACK (not connected)");
  } else if (error == 3) {
    Serial.println("❌ NACK on data");
  } else if (error == 4) {
    Serial.println("❌ Other error");
  } else {
    Serial.print("❌ Error code: ");
    Serial.println(error);
  }
}

void loop() {
  // Nothing here - run once
}
