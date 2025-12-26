#include <WiFi.h>
#include <WebServer.h>
#include <ESP32Servo.h>

// ================================================================
// 1. CONFIGURATION
// ================================================================
const char* ssid = "ESP32_Robot";      
const char* password = "password123";  

// Check your Pi IP! (Use hostname -I on Pi to confirm)
String piCameraURL = "http://10.176.131.22:5000/video_feed";

WebServer server(80);

// Status Variables
bool isAutoMode = false; 
bool isTrackingTrash = false; 
int manualSpeed = 200; // Strong speed
unsigned long lastTrashSeenTime = 0;

// --- PINS ---
const int pinServoX = 14; 
const int pinServoY = 13;  
const int pinBuzzer = 12;  

// Motor A (Left)
const int ENA = 27; const int IN1 = 26; const int IN2 = 25;
// Motor B (Right)
const int ENB = 23; const int IN3 = 33; const int IN4 = 32;

// Sensors
const int TRIG_F = 18;   const int ECHO_F = 35; 
const int TRIG_FL = 15; const int ECHO_FL = 2; 
const int TRIG_FR = 21; const int ECHO_FR = 19; 
const int TRIG_SL = 5;  const int ECHO_SL = 39; 
const int TRIG_SR = 99; const int ECHO_SR = 22; 

// UART (Communication with Pi)
#define RXD2 16
#define TXD2 17

Servo servoX;
Servo servoY;
int xAngle = 90;
int yAngle = 90;

// Auto Settings
int speedAutoNormal = 60; 
int speedAutoTurn   = 80; 
const int stopDist  = 25;  
const int avoidDist = 25;  
const int targetDist = 20; 

// ================================================================
// 2. MOTOR FUNCTIONS
// ================================================================
void moveForward(int spd) { 
  digitalWrite(IN1, HIGH); digitalWrite(IN2, LOW);
  digitalWrite(IN3, HIGH); digitalWrite(IN4, LOW);
  analogWrite(ENA, spd);   analogWrite(ENB, spd);
}
void moveBackward(int spd) { 
  digitalWrite(IN1, LOW); digitalWrite(IN2, HIGH);
  digitalWrite(IN3, LOW); digitalWrite(IN4, HIGH);
  analogWrite(ENA, spd);  analogWrite(ENB, spd);
}
void turnLeft(int spd) { 
  digitalWrite(IN1, LOW); digitalWrite(IN2, HIGH); 
  digitalWrite(IN3, HIGH); digitalWrite(IN4, LOW); 
  analogWrite(ENA, spd);  analogWrite(ENB, spd);
}
void turnRight(int spd) { 
  digitalWrite(IN1, HIGH); digitalWrite(IN2, LOW); 
  digitalWrite(IN3, LOW); digitalWrite(IN4, HIGH); 
  analogWrite(ENA, spd);  analogWrite(ENB, spd);
}
void stopCar() {
  digitalWrite(IN1, LOW); digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW); digitalWrite(IN4, LOW);
  analogWrite(ENA, 0);    analogWrite(ENB, 0);
}

int readSensor(int trigPin, int echoPin) {
  digitalWrite(trigPin, LOW); delayMicroseconds(2);
  digitalWrite(trigPin, HIGH); delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  long duration = pulseIn(echoPin, HIGH, 15000); 
  if (duration == 0) return 200; 
  return duration * 0.034 / 2;
}

// ================================================================
// 3. LOGIC HANDLERS
// ================================================================

void parseServoData(String data) {
  // Data Format: "x,y,beep" (e.g. "90,100,1")
  int firstComma = data.indexOf(',');
  int secondComma = data.indexOf(',', firstComma + 1);
  
  if (firstComma > 0 && secondComma > 0) {
    xAngle = data.substring(0, firstComma).toInt();
    yAngle = data.substring(firstComma + 1, secondComma).toInt();
    int beepStatus = data.substring(secondComma + 1).toInt();
    
    // Always update servos, even in manual mode (so eyes look at target)
    servoX.write(xAngle);
    servoY.write(yAngle);

    if (beepStatus == 1) {
      digitalWrite(pinBuzzer, HIGH);
      isTrackingTrash = true;
      lastTrashSeenTime = millis();
    } else {
      digitalWrite(pinBuzzer, LOW);
      if (millis() - lastTrashSeenTime > 2000) {
        isTrackingTrash = false;
      }
    }
  }
}

void handleWeb() { server.handleClient(); }
void handleRoot() { server.send(200, "text/html", "<h1>ESP32 Muscle Active</h1>"); }

// ================================================================
// 4. SETUP & LOOP
// ================================================================
void setup() {
  Serial.begin(115200);
  Serial2.begin(115200, SERIAL_8N1, RXD2, TXD2); // Comm with Pi

  pinMode(IN1, OUTPUT); pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT); pinMode(IN4, OUTPUT);
  pinMode(ENA, OUTPUT); pinMode(ENB, OUTPUT);

  pinMode(TRIG_F, OUTPUT); pinMode(ECHO_F, INPUT);
  pinMode(TRIG_FL, OUTPUT); pinMode(ECHO_FL, INPUT);
  pinMode(TRIG_FR, OUTPUT); pinMode(ECHO_FR, INPUT);
  
  servoX.attach(pinServoX); servoY.attach(pinServoY);
  servoX.write(90); servoY.write(90);

  pinMode(pinBuzzer, OUTPUT); digitalWrite(pinBuzzer, LOW);

  WiFi.softAP(ssid, password);
  server.on("/", handleRoot);
  server.begin();
}

void loop() {
  handleWeb(); // Keep this minimal if moving logic to Pi
  
  // --- READ COMMANDS FROM PI ---
  if (Serial2.available()) {
    String data = Serial2.readStringUntil('\n'); 
    data.trim();
    
    // CASE 1: Tracking Data (has commas)
    if (data.indexOf(',') > 0) {
       parseServoData(data);
    }
    // CASE 2: Command Characters
    else if (data.length() > 0) { 
       char cmd = data.charAt(0);
       
       // MANUAL COMMANDS -> FORCE AUTO OFF
       if (cmd == 'F') { isAutoMode = false; moveForward(manualSpeed); }
       else if (cmd == 'B') { isAutoMode = false; moveBackward(manualSpeed); }
       else if (cmd == 'L') { isAutoMode = false; turnLeft(manualSpeed); }
       else if (cmd == 'R') { isAutoMode = false; turnRight(manualSpeed); }
       else if (cmd == 'S') { isAutoMode = false; stopCar(); }
       
       // AUTO COMMAND -> FORCE AUTO ON
       else if (cmd == 'T') { 
          isAutoMode = true; 
          stopCar(); // Brief stop before starting logic
          // Optional: Beep to confirm
          digitalWrite(pinBuzzer, HIGH); delay(100); digitalWrite(pinBuzzer, LOW);
       }
    }
  }

  // --- EXECUTE AUTO LOGIC ---
  if (isAutoMode) {
    if (isTrackingTrash) runTrashChaserLogic();
    else runExplorerLogic();
  }
}

// ================================================================
// 5. AUTO LOGIC
// ================================================================
void runExplorerLogic() {
  int distF  = readSensor(TRIG_F, ECHO_F);
  int distFL = readSensor(TRIG_FL, ECHO_FL);
  int distFR = readSensor(TRIG_FR, ECHO_FR);

  // Note: We REMOVED servo centering here because the Pi controls the head sweep!
  // servoX.write(90); servoY.write(90); <--- REMOVED

  // Obstacle Avoidance
  if (distF < stopDist) {
    stopCar(); delay(100);
    moveBackward(speedAutoNormal); delay(400);
    stopCar();
    if (distFL > distFR) turnLeft(speedAutoTurn);
    else turnRight(speedAutoTurn);
    delay(600);
  }
  else if (distFL < avoidDist) { turnRight(speedAutoTurn); delay(250); }
  else if (distFR < avoidDist) { turnLeft(speedAutoTurn); delay(250); }
  else {
    moveForward(speedAutoNormal);
  }
  delay(50);
}

void runTrashChaserLogic() {
  int distFront = readSensor(TRIG_F, ECHO_F);
  
  if (distFront < targetDist) {
    // CAUGHT IT!
    stopCar(); 
    digitalWrite(pinBuzzer, HIGH); 
    delay(200);
    digitalWrite(pinBuzzer, LOW);
    delay(200);
    digitalWrite(pinBuzzer, HIGH); 
    delay(200);
    digitalWrite(pinBuzzer, LOW);
    
    isTrackingTrash = false; // Reset to explorer mode
    isAutoMode = false;      // Or stop completely? Your choice.
  }
  else {
    // Steer towards the object based on Servo X Angle
    // xAngle > 100 means object is to the LEFT
    // xAngle < 80 means object is to the RIGHT
    if (xAngle > 100) turnLeft(speedAutoTurn);
    else if (xAngle < 80) turnRight(speedAutoTurn);
    else moveForward(speedAutoNormal);
  }
  delay(50);
}