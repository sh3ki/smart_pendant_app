// Motor control pins
int IN1 = 26;   // Direction pin 1
int IN2 = 27;   // Direction pin 2
int ENA = 25;   // PWM speed (0–255)

void setup() {
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);

  // Setup PWM channel (channel 0, 5kHz, 8-bit resolution)
  ledcAttachPin(ENA, 0);
  ledcSetup(0, 5000, 8);
}

void loop() {

  // CLOCKWISE
  digitalWrite(IN1, HIGH);
  digitalWrite(IN2, LOW);
  ledcWrite(0, 200);   // speed (0–255)
  delay(2000);

  // STOP
  ledcWrite(0, 0);
  delay(1000);

  // COUNTER-CLOCKWISE
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);
  ledcWrite(0, 200);
  delay(2000);

  // STOP
  ledcWrite(0, 0);
  delay(1000);
}