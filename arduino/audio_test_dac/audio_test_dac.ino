/*
 * PAM8403 Audio Test Using ESP32 DAC (True Analog Output)
 * 
 * Arduino Nano ESP32 has built-in DAC (Digital-to-Analog Converter)
 * DAC pins: A0 (GPIO26) - Use this for audio!
 * 
 * NO FILTER NEEDED - DAC outputs real analog voltage!
 * 
 * Wiring:
 * - A0 (DAC) → PAM8403 L input pin
 * - 5V (from LM2596) → PAM8403 VCC
 * - GND → PAM8403 GND (shared with Arduino)
 * - Speaker → PAM8403 LOUT+ and LOUT-
 */

#define AUDIO_DAC_PIN A0   // A0 = GPIO26 = DAC output

void setup() {
  Serial.begin(115200);
  delay(2000);
  
  Serial.println("\n╔════════════════════════════════════════╗");
  Serial.println("║   🔊 PAM8403 AUDIO TEST (DAC MODE)    ║");
  Serial.println("╚════════════════════════════════════════╝\n");
  
  Serial.println("✅ Using ESP32 DAC (true analog output) - NO FILTER NEEDED!");
  Serial.println();
  Serial.println("🔌 WIRING:");
  Serial.println("   - A0 pin → PAM8403 L input");
  Serial.println("   - 5V → PAM8403 VCC");
  Serial.println("   - GND → PAM8403 GND");
  Serial.println("   - Speaker → LOUT+ and LOUT-");
  Serial.println();
  
  Serial.println("🔊 STARTING AUDIO TEST - Listen for 3 LOUD beeps...\n");
  
  // Generate 3 test beeps using DAC
  for (int i = 0; i < 3; i++) {
    Serial.print("   🔊 BEEP ");
    Serial.print(i + 1);
    Serial.println("/3 - LISTEN NOW!");
    
    // Generate 1kHz tone for 500ms
    // 1kHz = 1000 cycles per second = 1ms per cycle
    // Sample rate: 8kHz = 8 samples per cycle
    unsigned long beepStart = millis();
    while (millis() - beepStart < 500) {  // 500ms beep
      // Generate sine wave at 1kHz
      for (int sample = 0; sample < 8; sample++) {
        // Simple square wave for loudness
        if (sample < 4) {
          dacWrite(AUDIO_DAC_PIN, 200);  // High (loud)
        } else {
          dacWrite(AUDIO_DAC_PIN, 55);   // Low
        }
        delayMicroseconds(125);  // 8kHz sample rate (1000000/8000 = 125us)
      }
    }
    
    // Silence (midpoint = 127)
    dacWrite(AUDIO_DAC_PIN, 127);
    delay(300);  // Wait 300ms between beeps
  }
  
  Serial.println("\n✅ Audio test complete!\n");
  
  // Set to midpoint (silence)
  dacWrite(AUDIO_DAC_PIN, 127);
  
  Serial.println("❓ DID YOU HEAR THE BEEPS?");
  Serial.println();
  Serial.println("   ✅ YES, I heard beeps:");
  Serial.println("      → DAC audio works!");
  Serial.println("      → Use A0 pin for all audio in your main code");
  Serial.println();
  Serial.println("   ❌ NO, I heard nothing:");
  Serial.println("      → Check A0 wire goes to PAM8403 'L' pin");
  Serial.println("      → Turn PAM8403 volume knob CLOCKWISE");
  Serial.println("      → Verify 5V power to PAM8403");
  Serial.println("      → Try a different speaker");
  Serial.println();
  
  Serial.println("🔁 Test will repeat in 5 seconds...\n");
  delay(5000);
}

void loop() {
  // Repeat the test every 10 seconds
  Serial.println("🔊 REPEATING TEST - Listen for 3 beeps...\n");
  
  for (int i = 0; i < 3; i++) {
    Serial.print("   🔊 BEEP ");
    Serial.print(i + 1);
    Serial.println("/3");
    
    // Generate 1kHz square wave for 500ms
    unsigned long beepStart = millis();
    while (millis() - beepStart < 500) {
      for (int sample = 0; sample < 8; sample++) {
        dacWrite(AUDIO_DAC_PIN, (sample < 4) ? 200 : 55);
        delayMicroseconds(125);
      }
    }
    
    dacWrite(AUDIO_DAC_PIN, 127);  // Silence
    delay(300);
  }
  
  Serial.println("   ✅ Test complete. Waiting 10 seconds...\n");
  delay(10000);
}
