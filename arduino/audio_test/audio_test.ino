/*
 * PAM8403 Audio Test for Arduino Nano ESP32
 * 
 * This test generates 3 loud beeps on D9 with 1kΩ resistor to verify:
 * - PAM8403 is powered (5V)
 * - Volume knob is turned up
 * - Speaker is connected properly
 * - 1kΩ resistor + D9 wire connected to PAM8403 L-IN
 * 
 * Wiring:
 * - D9 → 1kΩ resistor → PAM8403 L-IN (left channel input)
 * - 5V (from LM2596) → PAM8403 VCC
 * - GND → PAM8403 GND
 * - Speaker → PAM8403 LOUT+ and LOUT-
 */

#define AUDIO_PIN 9        // D9 connected to PAM8403 L-IN
#define PWM_CHANNEL 0      // ESP32 PWM channel

void setup() {
  Serial.begin(115200);
  delay(2000);
  
  Serial.println("\n╔════════════════════════════════════════╗");
  Serial.println("║   🔊 PAM8403 AUDIO HARDWARE TEST      ║");
  Serial.println("╚════════════════════════════════════════╝\n");
  
  Serial.println("🔍 TROUBLESHOOTING CHECKLIST:");
  Serial.println("   1. PAM8403 blue volume knob - turn CLOCKWISE (to the right)");
  Serial.println("   2. PAM8403 power LED - should be lit (red/green)");
  Serial.println("   3. Measure 5V on PAM8403 VCC pin with multimeter");
  Serial.println("   4. Speaker connected to SPK+ and SPK- on PAM8403");
  Serial.println("   5. D9 wire goes to L-IN pin on PAM8403 (NOT L+ or VCC!)");
  Serial.println();
  
  // Initialize audio pin
  pinMode(AUDIO_PIN, OUTPUT);
  digitalWrite(AUDIO_PIN, LOW);
  
  Serial.println("🔊 STARTING AUDIO TEST - Listen for 3 LOUD beeps...\n");
  
  // Setup PWM: Use HIGH carrier frequency (40kHz) for PAM8403
  // Then modulate it at audio frequency (1kHz) for beep tone
  ledcSetup(PWM_CHANNEL, 40000, 8);  // Channel 0, 40kHz carrier, 8-bit (0-255)
  ledcAttachPin(AUDIO_PIN, PWM_CHANNEL);
  
  // Generate 3 test beeps with 1kHz modulation
  for (int i = 0; i < 3; i++) {
    Serial.print("   🔊 BEEP ");
    Serial.print(i + 1);
    Serial.println("/3 - LISTEN NOW!");
    
    // Generate 1kHz tone by toggling PWM duty cycle at 1kHz (audio frequency)
    unsigned long beepStart = millis();
    while (millis() - beepStart < 500) {  // 500ms beep
      // 1kHz = 1ms period, so toggle every 0.5ms
      ledcWrite(PWM_CHANNEL, 192);  // High (75% duty)
      delayMicroseconds(500);       // 0.5ms
      ledcWrite(PWM_CHANNEL, 64);   // Low (25% duty)
      delayMicroseconds(500);       // 0.5ms
    }
    
    // Silence (neutral midpoint)
    ledcWrite(PWM_CHANNEL, 128);
    delay(300);  // Wait 300ms between beeps
  }
  
  Serial.println("\n✅ Audio test complete!\n");
  
  // Clean up PWM
  ledcDetachPin(AUDIO_PIN);
  pinMode(AUDIO_PIN, OUTPUT);
  digitalWrite(AUDIO_PIN, LOW);
  
  Serial.println("❓ DID YOU HEAR THE BEEPS?");
  Serial.println();
  Serial.println("   ✅ YES, I heard beeps:");
  Serial.println("      → Audio hardware is working!");
  Serial.println("      → Volume is good");
  Serial.println("      → Your main firmware should work");
  Serial.println();
  Serial.println("   ❌ NO, I heard nothing:");
  Serial.println("      → Turn PAM8403 blue knob CLOCKWISE");
  Serial.println("      → Check if PAM8403 power LED is ON");
  Serial.println("      → Measure 5V with multimeter on PAM8403 VCC");
  Serial.println("      → Try a different speaker");
  Serial.println("      → Verify D9 wire goes to L-IN (not L+ or GND)");
  Serial.println();
  
  Serial.println("💡 TIP: If you have a multimeter:");
  Serial.println("   - Set to DC voltage mode");
  Serial.println("   - Measure between PAM8403 VCC and GND");
  Serial.println("   - Should read ~5V (4.8V - 5.2V is OK)");
  Serial.println("   - If 0V or wrong voltage, check LM2596 buck converter");
  Serial.println();
  
  Serial.println("🔁 Test will repeat in 5 seconds...\n");
  delay(5000);
}

void loop() {
  // Repeat the test every 10 seconds
  Serial.println("🔊 REPEATING TEST - Listen for 3 beeps...\n");
  
  ledcSetup(PWM_CHANNEL, 40000, 8);  // 40kHz carrier frequency
  ledcAttachPin(AUDIO_PIN, PWM_CHANNEL);
  
  for (int i = 0; i < 3; i++) {
    Serial.print("   🔊 BEEP ");
    Serial.print(i + 1);
    Serial.println("/3");
    
    // Generate 1kHz tone by modulating 40kHz carrier
    unsigned long beepStart = millis();
    while (millis() - beepStart < 500) {
      ledcWrite(PWM_CHANNEL, 192);  // High
      delayMicroseconds(500);
      ledcWrite(PWM_CHANNEL, 64);   // Low
      delayMicroseconds(500);
    }
    
    ledcWrite(PWM_CHANNEL, 128);  // Neutral (silence)
    delay(300);
  }
  
  ledcDetachPin(AUDIO_PIN);
  pinMode(AUDIO_PIN, OUTPUT);
  digitalWrite(AUDIO_PIN, LOW);
  
  Serial.println("   ✅ Test complete. Waiting 10 seconds...\n");
  delay(10000);  // Wait 10 seconds before next test
}
