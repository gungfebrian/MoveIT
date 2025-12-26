#include <WiFi.h>
#include <WebServer.h>
#include <ESP32Servo.h>

// ================================================================
// 1. CONFIGURATION & PINS
// ================================================================
const char* ssid = "ESP32_Robot";      
const char* password = "password123";  

// GANTI IP INI SESUAI IP RASPBERRY PI KAMU!
String piCameraURL = "http://192.168.4.2:5000/video_feed";

WebServer server(80);

// Status Variables
bool isAutoMode = false; 
bool isTrackingTrash = false; 
int manualSpeed = 255; // SET KE MAX (255) AGAR TIDAK JITTER
unsigned long lastTrashSeenTime = 0;

// --- SERVO & BUZZER ---
const int pinServoX = 14; 
const int pinServoY = 13;  
const int pinBuzzer = 12;  

// --- MOTOR PINS (Sesuai Tes Terakhir) ---
// Motor A (Left)
const int ENA = 27; const int IN1 = 26; const int IN2 = 25;
// Motor B (Right)
const int ENB = 23; const int IN3 = 33; const int IN4 = 32;

// --- SENSOR PINS ---
const int TRIG_F = 18;   const int ECHO_F = 35; 
const int TRIG_FL = 15; const int ECHO_FL = 2; 
const int TRIG_FR = 21; const int ECHO_FR = 19; 
const int TRIG_SL = 5;  const int ECHO_SL = 39; //hapus
const int TRIG_SR = 99; const int ECHO_SR = 22; //hapus

// --- UART PINS ---
#define RXD2 16
#define TXD2 17

Servo servoX;
Servo servoY;
int xAngle = 90;
int yAngle = 90;

// Auto Mode Tuning (Kecepatan dinaikkan agar kuat)
int speedAutoNormal = 95; 
int speedAutoTurn   = 105; 
const int stopDist  = 25;  
const int avoidDist = 30;  
const int sideDist  = 25;  
const int targetDist = 25; 

// ================================================================
// 2. FORWARD DECLARATIONS
// ================================================================
void runExplorerLogic();
void runTrashChaserLogic();
void moveForward(int spd);
void moveBackward(int spd);
void turnLeft(int spd);
void turnRight(int spd);
void stopCar();
int readSensor(int trigPin, int echoPin);
void parseServoData(String data);

// ================================================================
// 3. MOTOR FUNCTIONS (Sederhana & Kuat)
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
  digitalWrite(IN1, LOW); digitalWrite(IN2, HIGH); // Kiri Mundur
  digitalWrite(IN3, HIGH); digitalWrite(IN4, LOW); // Kanan Maju
  analogWrite(ENA, spd);  analogWrite(ENB, spd);
}

void turnRight(int spd) { 
  digitalWrite(IN1, HIGH); digitalWrite(IN2, LOW); // Kiri Maju
  digitalWrite(IN3, LOW); digitalWrite(IN4, HIGH); // Kanan Mundur
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

void parseServoData(String data) {
  int firstComma = data.indexOf(',');
  int secondComma = data.indexOf(',', firstComma + 1);
  if (firstComma > 0 && secondComma > 0) {
    String xStr = data.substring(0, firstComma);
    String yStr = data.substring(firstComma + 1, secondComma);
    String beepStr = data.substring(secondComma + 1);
    
    xAngle = xStr.toInt();
    yAngle = yStr.toInt();
    int beepStatus = beepStr.toInt();
    
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

// ================================================================
// 4. WEB PAGE GENERATOR
// ================================================================
String getPage() {
  String p = "<!DOCTYPE HTML><html><head>";
  p += "<meta name='viewport' content='width=device-width, initial-scale=1'>";
  p += "<title>Smart Robot</title>";
  p += "<style>";
  p += "body { font-family: monospace; background: #0d0d0d; color: #00ffcc; text-align: center; margin: 0; padding: 10px; }";
  p += "h2 { margin: 10px 0; text-shadow: 0 0 10px rgba(0,255,204,0.5); }";
  p += ".cam { border: 2px solid #00ffcc; border-radius: 10px; width: 100%; max-width: 400px; height: auto; margin: 0 auto; background: #000; display: block; }";
  p += ".panel { background: #1a1a1a; padding: 10px; border-radius: 10px; margin: 10px auto; max-width: 400px; border: 1px solid #333; }";
  p += "#chat-log { height: 60px; overflow-y: auto; font-size: 14px; text-align: left; padding: 5px; border-bottom: 1px solid #333; margin-bottom: 10px; color: #fff; }";
  p += ".user-msg { color: #aaa; } .bot-msg { color: #00ffcc; font-weight: bold; }";
  p += ".mic-btn { width: 100%; max-width: 380px; padding: 15px; font-size: 18px; font-weight: bold; border-radius: 30px; background: #222; color: #fff; border: 2px solid #00ffcc; transition: 0.2s; margin-bottom: 15px; }";
  p += ".mic-btn.listening { background: #ff0000; border-color: #ff0000; animation: pulse 1.5s infinite; }";
  p += "@keyframes pulse { 0% {box-shadow: 0 0 0 0 rgba(255,0,0,0.7);} 70% {box-shadow: 0 0 0 10px rgba(255,0,0,0);} 100% {box-shadow: 0 0 0 0 rgba(255,0,0,0);} }";
  p += ".btn { background: #222; border: 1px solid #444; border-radius: 8px; color: #fff; font-size: 24px; width: 70px; height: 60px; margin: 5px; touch-action: manipulation; }";
  p += ".btn:active { background: #00ffcc; color: #000; }";
  p += ".honk { background: #d9534f; width: 100px; font-size: 16px; height: 50px; border:none; }";
  p += ".row { display: flex; justify-content: center; }";
  p += "</style></head><body>";

  p += "<h2>ROBOT COMMANDER</h2>";
  p += "<img id='piStream' class='cam' src='" + piCameraURL + "' alt='WAITING FOR PI...'>";

  p += "<div class='panel'>";
  p += "  <div id='chat-log'><span class='bot-msg'>System:</span> Ready...</div>";
  p += "  <div style='margin-top:5px; font-size:12px; color:#888;'>";
  p += "    STATUS: <span id='mode' style='color:#fff'>MANUAL</span> | SPD: <span id='spd' style='color:#fff'>255</span>";
  p += "  </div>";
  p += "</div>";

  p += "<input type='range' min='100' max='255' value='255' style='width:90%; max-width:300px; margin-bottom:15px;' onchange='setSpd(this.value)' oninput='updSpd(this.value)'>";
  p += "<button id='micBtn' class='mic-btn' onclick='toggleMic()'>🎤 TAP TO SPEAK</button>";

  p += "<div class='row'><button class='btn' onpointerdown='mv(\"F\")' onpointerup='mv(\"S\")'>▲</button></div>";
  p += "<div class='row'>";
  p += "  <button class='btn' onpointerdown='mv(\"L\")' onpointerup='mv(\"S\")'>◄</button>";
  p += "  <button class='btn' onclick='mv(\"S\")'>■</button>";
  p += "  <button class='btn' onpointerdown='mv(\"R\")' onpointerup='mv(\"S\")'>►</button>";
  p += "</div>";
  p += "<div class='row'><button class='btn' onpointerdown='mv(\"B\")' onpointerup='mv(\"S\")'>▼</button></div>";

  p += "<br><button class='btn honk' onpointerdown='h(1)' onpointerup='h(0)'>HONK</button> ";
  p += "<button class='btn' style='width:100px; height:50px; font-size:16px; background:#007bff; border:none;' onclick='tog()'>MODE</button>";

  p += "<script>";
  p += "var piBase = '" + piCameraURL + "';"; 
  p += "piBase = piBase.replace('/video_feed', '');";

  p += "function setSpd(v){ fetch('/speed?value='+v); }";
  p += "function updSpd(v){ document.getElementById('spd').innerText=v; }";
  p += "function mv(d){ fetch('/action?go='+d); }";
  p += "function h(s){ fetch('/honk?s='+s); }";
  p += "function tog(){ fetch('/toggle').then(r=>r.text()).then(t=>{ ";
  p += "  document.getElementById('mode').innerText=t; ";
  p += "}); }";

  p += "var recognition;";
  p += "var isListening = false;";

  p += "if('webkitSpeechRecognition' in window){";
  p += "  recognition = new webkitSpeechRecognition();";
  p += "  recognition.continuous = false;";
  p += "  recognition.lang = 'id-ID';"; 
  p += "  recognition.onresult = function(e){";
  p += "    var txt = e.results[0][0].transcript;";
  p += "    logChat('You', txt); sendVoiceToPi(txt);";
  p += "  };";
  p += "  recognition.onend = function(){";
  p += "    isListening = false;";
  p += "    document.getElementById('micBtn').classList.remove('listening');"; 
  p += "    document.getElementById('micBtn').innerText='🎤 TAP TO SPEAK';"; 
  p += "  };";
  p += "}";

  p += "function toggleMic(){"; 
  p += "  if(!recognition) { alert('Use Chrome'); return; }";
  p += "  if(isListening) {";
  p += "    recognition.stop();"; 
  p += "  } else {";
  p += "    recognition.start();"; 
  p += "    isListening = true;";
  p += "    document.getElementById('micBtn').classList.add('listening');"; 
  p += "    document.getElementById('micBtn').innerText='LISTENING... (TAP TO STOP)';"; 
  p += "  }";
  p += "}";

  p += "function sendVoiceToPi(txt){";
  p += "  fetch(piBase + '/chat?text=' + encodeURIComponent(txt))";
  p += "    .then(r => r.text())";
  p += "    .then(reply => { logChat('Robot', reply); })";
  p += "    .catch(e => logChat('System', 'Pi Offline'));";
  p += "}";

  p += "function logChat(who, msg){";
  p += "  var log = document.getElementById('chat-log');";
  p += "  var color = (who == 'You') ? 'user-msg' : 'bot-msg';";
  p += "  log.innerHTML = '<span class=\"'+color+'\">' + who + ':</span> ' + msg;";
  p += "}";

  p += "</script></body></html>";
  return p;
}

// ================================================================
// 5. SERVER HANDLERS
// ================================================================
void handleRoot() { server.send(200, "text/html", getPage()); }

void handleSpeed() { if (server.hasArg("value")) manualSpeed = server.arg("value").toInt(); server.send(200, "text/plain", "OK"); }

void handleAction() {
  if (isAutoMode) return;
  if (server.hasArg("go")) {
    String go = server.arg("go");
    if (go == "F") moveForward(manualSpeed);
    else if (go == "B") moveBackward(manualSpeed);
    else if (go == "L") turnLeft(manualSpeed);
    else if (go == "R") turnRight(manualSpeed);
    else if (go == "S") stopCar();
  }
  server.send(200, "text/plain", "OK");
}

void handleHonk() {
  if (server.hasArg("s")) {
    int s = server.arg("s").toInt();
    digitalWrite(pinBuzzer, s ? HIGH : LOW);
  }
  server.send(200, "text/plain", "OK");
}

void handleToggle() { isAutoMode = !isAutoMode; stopCar(); server.send(200, "text/plain", isAutoMode ? "AUTO" : "MANUAL"); }

// ================================================================
// 6. SETUP & LOOP
// ================================================================
void setup() {
  Serial.begin(115200);
  Serial2.begin(115200, SERIAL_8N1, RXD2, TXD2);

  pinMode(IN1, OUTPUT); pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT); pinMode(IN4, OUTPUT);
  pinMode(ENA, OUTPUT); pinMode(ENB, OUTPUT);

  pinMode(TRIG_F, OUTPUT); pinMode(ECHO_F, INPUT);
  pinMode(TRIG_FL, OUTPUT); pinMode(ECHO_FL, INPUT);
  pinMode(TRIG_FR, OUTPUT); pinMode(ECHO_FR, INPUT);
  pinMode(TRIG_SL, OUTPUT); pinMode(ECHO_SL, INPUT);
  pinMode(TRIG_SR, OUTPUT); pinMode(ECHO_SR, INPUT);

  servoX.setPeriodHertz(50); servoY.setPeriodHertz(50);
  servoX.attach(pinServoX, 500, 2400);
  servoY.attach(pinServoY, 500, 2400);
  servoX.write(90); servoY.write(90);

  pinMode(pinBuzzer, OUTPUT);
  digitalWrite(pinBuzzer, LOW);

  WiFi.softAP(ssid, password);
  server.on("/", handleRoot);
  server.on("/action", handleAction);
  server.on("/honk", handleHonk);
  server.on("/toggle", handleToggle);
  server.on("/speed", handleSpeed);
  server.begin();
}

void loop() {
  server.handleClient();
  
  if (Serial2.available()) {
    String data = Serial2.readStringUntil('\n'); 
    data.trim();
    if (data.indexOf(',') > 0) parseServoData(data);
    else if (!isAutoMode && data.length() == 1) {
       char cmd = data.charAt(0);
       if (cmd == 'F') moveForward(manualSpeed);
       else if (cmd == 'B') moveBackward(manualSpeed);
       else if (cmd == 'L') turnLeft(manualSpeed);
       else if (cmd == 'R') turnRight(manualSpeed);
       else if (cmd == 'S') stopCar();
    }
  }

  if (isAutoMode) {
    if (isTrackingTrash) runTrashChaserLogic();
    else runExplorerLogic();
  }
}

// ================================================================
// 7. AUTO LOGIC: EXPLORER
// ================================================================
void runExplorerLogic() {
  int distF  = readSensor(TRIG_F, ECHO_F);
  int distFL = readSensor(TRIG_FL, ECHO_FL);
  int distFR = readSensor(TRIG_FR, ECHO_FR);
  int distSL = readSensor(TRIG_SL, ECHO_SL);
  int distSR = readSensor(TRIG_SR, ECHO_SR);

  servoX.write(90); servoY.write(90); 

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
  else if (distSL < sideDist) {
    digitalWrite(IN1, HIGH); digitalWrite(IN2, LOW); digitalWrite(IN3, HIGH); digitalWrite(IN4, LOW);
    analogWrite(ENA, speedAutoNormal + 20); analogWrite(ENB, speedAutoNormal - 30);
  }
  else if (distSR < sideDist) {
    digitalWrite(IN1, HIGH); digitalWrite(IN2, LOW); digitalWrite(IN3, HIGH); digitalWrite(IN4, LOW);
    analogWrite(ENA, speedAutoNormal - 30); analogWrite(ENB, speedAutoNormal + 20);
  }
  else {
    moveForward(speedAutoNormal);
  }
  delay(50);
}

// ================================================================
// 8. AUTO LOGIC: TRASH CHASER
// ================================================================
void runTrashChaserLogic() {
  int distFront = readSensor(TRIG_F, ECHO_F);
  if (distFront < targetDist) {
    stopCar(); 
    digitalWrite(pinBuzzer, HIGH); 
    delay(100);
    digitalWrite(pinBuzzer, LOW);
  }
  else {
    if (xAngle > 110) turnLeft(speedAutoTurn);
    else if (xAngle < 70) turnRight(speedAutoTurn);
    else moveForward(speedAutoNormal);
  }
  delay(50);
}