from flask import Flask, render_template_string, request, jsonify, Response
from picamera2 import Picamera2
from ultralytics import YOLO
import cv2
import serial
import time
import numpy as np
import threading
import speech_recognition as sr
from gtts import gTTS
import pygame
import json
import os


# =======================
# CONFIGURATION
# =======================
SERIAL_PORT = "/dev/serial0"
BAUDRATE = 115200


# --- OPTIMIZATION SETTINGS ---
HEADLESS_MODE = False      # Set False so we see the stream on ESP32 Dashboard
SKIP_FRAMES = 3           # Run AI only every N frames
CONF_THRESHOLD = 0.4      # Confidence threshold
MODEL_FILE = 'yolov8n.pt' # Ensure this file exists


# =======================
# HARDWARE SETUP
# =======================
# 1. AI Models (YOLO Only - No Gemini)
print(f"🚀 Loading YOLO Model ({MODEL_FILE})...")
model = YOLO(MODEL_FILE)


# 2. Serial (ESP32)
try:
   ser = serial.Serial(SERIAL_PORT, baudrate=BAUDRATE, timeout=0.1)
   print(f"✅ Connected to ESP32 on {SERIAL_PORT}")
except:
   print("⚠️ WARNING: ESP32 NOT CONNECTED (Simulation Mode)")
   ser = None


# 3. Camera (Picamera2)
try:
   picam2 = Picamera2()
   config = picam2.create_preview_configuration(main={"size": (640, 480), "format": "RGB888"})
   picam2.configure(config)
   picam2.start()
   print("✅ Camera Started")
except Exception as e:
   print(f"❌ Camera Error: {e}")


# 4. Flask App
app = Flask(__name__)


# =======================
# GLOBAL VARIABLES
# =======================
curr_x, curr_y = 90, 90   # Servo positions
step, margin = 4, 60      # Tracking sensitivity
timeout_sec = 5.0
is_speaking = False
is_processing_command = False
frame_count = 0


# Shared buffer for Video Streaming
global_frame_jpg = None
frame_lock = threading.Lock()


# =======================
# AUDIO & LOGIC FUNCTIONS
# =======================
def robot_speak(text):
   """Text to Speech Output"""
   global is_speaking
   is_speaking = True
   print(f"🤖 Robot: {text}")
   try:
       # Saving to /tmp/ is faster (RAM disk)
       tts = gTTS(text=text, lang='id')
       tts.save("/tmp/response.mp3")
       pygame.mixer.init()
       pygame.mixer.music.load("/tmp/response.mp3")
       pygame.mixer.music.play()
       while pygame.mixer.music.get_busy():
           continue
   except Exception as e:
       print(f"Audio Error: {e}")
   is_speaking = False


def send_uart_command(action, duration=0):
   """Helper to send commands reliably to ESP32"""
   if ser:
       command_str = f"{action}\n"
       ser.write(command_str.encode('utf-8'))
       print(f"⚡ Sent to ESP32: {command_str.strip()}")
      
       if duration > 0:
           time.sleep(duration)
           ser.write(b'S\n') # Auto-stop if duration provided


def process_voice_command(user_text):
   """
   LOCAL REFLEX BRAIN:
   Zero latency, Zero API cost. Handles commands via keywords.
   """
   global is_processing_command
   if not user_text: return
  
   is_processing_command = True
   text_lower = user_text.lower()
   print(f"🗣️ Processing Command: {user_text}")


   # --- LOCAL COMMAND MAPPING ---
  
   # STOP
   if "stop" in text_lower or "berhenti" in text_lower or "diam" in text_lower:
       send_uart_command('S')
       robot_speak("Berhenti.")


   # FORWARD (Maju)
   elif "maju" in text_lower:
       robot_speak("Maju.")
       send_uart_command('F')


   # BACKWARD (Mundur)
   elif "mundur" in text_lower:
       robot_speak("Mundur.")
       send_uart_command('B')


   # ROTATE (Berputar -> Right)
   elif "berputar" in text_lower or "putar" in text_lower:
       robot_speak("Berputar.")
       # 'R' is Right/Rotate
       send_uart_command('R', duration=1.0)


   # AUTO MODE (Cari Sampah)
   elif "cari sampah" in text_lower or "sampah" in text_lower:
       robot_speak("Siap, mencari sampah.")
       send_uart_command('T') # Send 'T' for Trash/Tracking Mode


   else:
       robot_speak("Perintah tidak dikenal.")


   is_processing_command = False


# =======================
# THREAD 1: AI VISION LOOP (Background)
# =======================
def ai_logic_loop():
   """
   Runs YOLO Object Tracking continuously.
   Updates global_frame_jpg for the video stream.
   """
   global curr_x, curr_y, frame_count, global_frame_jpg
  
   print("🧠 AI Vision Thread Started...")
   last_seen_time = time.time()
  
   while True:
       try:
           # 1. Capture Image
           frame_rgb = picam2.capture_array()
          
           # Convert to BGR for OpenCV/YOLO
           frame_bgr = cv2.cvtColor(frame_rgb, cv2.COLOR_RGB2BGR)
           rows, cols, _ = frame_bgr.shape
           center_x = cols // 2
           center_y = rows // 2
          
           # 2. Run AI logic (Skipping frames for speed)
           frame_count += 1
           should_run_ai = (frame_count % SKIP_FRAMES == 0) and (not is_processing_command)


           if should_run_ai:
               results = model(frame_bgr, imgsz=160, stream=True, verbose=False, conf=CONF_THRESHOLD)
              
               found_target = False
               beep_trigger = 0


               for r in results:
                   boxes = r.boxes
                   for box in boxes:
                       cls_id = int(box.cls[0])
                       # 39=Bottle, 41=Cup
                       if cls_id == 39 or cls_id == 41:
                           found_target = True
                           last_seen_time = time.time()
                          
                           x1, y1, x2, y2 = box.xyxy[0]
                           obj_x = int((x1 + x2) / 2)
                           obj_y = int((y1 + y2) / 2)


                           # Draw Box
                           cv2.rectangle(frame_bgr, (int(x1), int(y1)), (int(x2), int(y2)), (0, 255, 0), 2)


                           # --- SERVO TRACKING LOGIC ---
                           if obj_x < center_x - margin: curr_x += step
                           elif obj_x > center_x + margin: curr_x -= step
                          
                           if obj_y < center_y - margin: curr_y -= step
                           elif obj_y > center_y + margin: curr_y += step


                           # Clamp values
                           curr_x = max(0, min(180, curr_x))
                           curr_y = max(70, min(120, curr_y))


                           if float(box.conf[0]) > 0.7: beep_trigger = 1
                           break
                   if found_target: break


               if not found_target and (time.time() - last_seen_time > timeout_sec):
                   curr_x = 90
                   curr_y = 90


               # --- SEND TO ESP32 (Already had newline, so this was fine) ---
               if ser:
                   msg = f"{curr_x},{curr_y},{beep_trigger}\n"
                   ser.write(msg.encode('utf-8'))
          
           # 3. Update Video Stream Buffer
           ret, buffer = cv2.imencode('.jpg', frame_bgr)
           if ret:
               with frame_lock:
                   global_frame_jpg = buffer.tobytes()


       except Exception as e:
           time.sleep(0.01)


# =======================
# VIDEO GENERATOR
# =======================
def generate_frames():
   while True:
       with frame_lock:
           if global_frame_jpg is None:
               continue
           data = global_frame_jpg
      
       yield (b'--frame\r\n'
              b'Content-Type: image/jpeg\r\n\r\n' + data + b'\r\n')
       time.sleep(0.05)


# =======================
# WEB INTERFACE (HTML)
# =======================
HTML_PAGE = """
<!DOCTYPE html>
<html lang="en">
<head>
   <meta charset="UTF-8">
   <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
   <title>Hybrid Athlete Robot</title>
   <style>
       :root { --primary: #00ff88; --bg: #121212; --panel: #1e1e1e; }
       body {
           font-family: 'Courier New', monospace;
           background: var(--bg);
           color: var(--primary);
           text-align: center;
           margin: 0; padding: 10px;
           overscroll-behavior: none;
       }
       h1 { margin: 10px 0; font-size: 1.5rem; text-shadow: 0 0 10px var(--primary); }
      
       /* Video Feed Container */
       .cam-container {
           position: relative;
           width: 100%;
           max-width: 480px;
           margin: 0 auto;
           border: 2px solid var(--primary);
           border-radius: 10px;
           overflow: hidden;
           background: #000;
       }
       .cam-feed { width: 100%; height: auto; display: block; }
      
       /* Status Log */
       .status-box {
           margin: 10px auto;
           padding: 10px;
           width: 90%;
           max-width: 460px;
           background: var(--panel);
           border: 1px solid #333;
           border-radius: 5px;
           color: #fff;
           font-size: 0.9rem;
           min-height: 40px;
       }


       /* Controls Grid */
       .controls {
           display: grid;
           grid-template-columns: repeat(3, 1fr);
           gap: 10px;
           max-width: 300px;
           margin: 20px auto;
       }
       .btn {
           background: var(--panel);
           border: 1px solid var(--primary);
           color: var(--primary);
           padding: 15px 0;
           font-size: 1.5rem;
           border-radius: 10px;
           cursor: pointer;
           touch-action: manipulation; /* Prevents double-tap zoom */
           user-select: none;
           transition: background 0.1s, transform 0.1s;
       }
       .btn:active { background: var(--primary); color: #000; transform: scale(0.95); }
       .btn-mic {
           grid-column: 1 / -1;
           background: #0044ff; color: white; border: none;
           display: flex; align-items: center; justify-content: center; gap: 10px;
       }
       .btn-mic.recording { background: #ff0044; animation: pulse 1s infinite; }
      
       .btn-auto { grid-column: 1 / -1; background: #ffaa00; color: #000; font-weight: bold; font-size: 1.2rem; }


       @keyframes pulse { 0% { opacity: 1; } 50% { opacity: 0.7; } 100% { opacity: 1; } }
   </style>
</head>
<body>


   <h1>COMMAND CENTER</h1>


   <!-- 1. VIDEO FEED (Hosted by Pi) -->
   <div class="cam-container">
       <img class="cam-feed" src="/video_feed" alt="Video Stream Loading...">
   </div>


   <!-- 2. STATUS LOG -->
   <div id="status" class="status-box">System Ready.</div>


   <!-- 3. CONTROLS -->
   <div class="controls">
       <!-- Microphone -->
       <button id="micBtn" class="btn btn-mic" onclick="toggleMic()">
           <span>🎤</span> <span id="micText">VOICE COMMAND</span>
       </button>


       <!-- D-Pad -->
       <div></div>
       <button class="btn" onpointerdown="send('F')" onpointerup="send('S')">▲</button>
       <div></div>


       <button class="btn" onpointerdown="send('L')" onpointerup="send('S')">◄</button>
       <button class="btn" onclick="send('S')">■</button>
       <button class="btn" onpointerdown="send('R')" onpointerup="send('S')">►</button>


       <div></div>
       <button class="btn" onpointerdown="send('B')" onpointerup="send('S')">▼</button>
       <div></div>


       <!-- Auto Mode -->
       <button class="btn btn-auto" onclick="send('T')">♻️ CARI SAMPAH</button>
   </div>


   <script>
       // --- MANUAL CONTROL (Sends to Pi, Pi sends to ESP32) ---
       function send(action) {
           fetch('/manual_cmd', {
               method: 'POST',
               headers: {'Content-Type': 'application/json'},
               body: JSON.stringify({cmd: action})
           }).catch(e => console.error("Error:", e));
          
           if(action === 'T') document.getElementById('status').innerText = "MODE: AUTO SEARCH";
           else if(action !== 'S') document.getElementById('status').innerText = "Manual: " + action;
       }


       // --- VOICE CONTROL ---
       let isRecording = false;
       let recognition;


       if ('webkitSpeechRecognition' in window || 'SpeechRecognition' in window) {
           const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
           recognition = new SpeechRecognition();
           recognition.continuous = false;
           recognition.lang = 'id-ID';
          
           recognition.onstart = function() {
               isRecording = true;
               document.getElementById('micBtn').classList.add('recording');
               document.getElementById('micText').innerText = "LISTENING...";
               document.getElementById('status').innerText = "Listening...";
           };


           recognition.onend = function() {
               isRecording = false;
               document.getElementById('micBtn').classList.remove('recording');
               document.getElementById('micText').innerText = "VOICE COMMAND";
           };


           recognition.onresult = function(event) {
               const transcript = event.results[0][0].transcript;
               document.getElementById('status').innerText = "Voice: " + transcript;
              
               fetch('/process_voice', {
                   method: 'POST',
                   headers: {'Content-Type': 'application/json'},
                   body: JSON.stringify({text: transcript})
               });
           };
       } else {
           document.getElementById('status').innerText = "Browser doesn't support Voice.";
       }


       function toggleMic() {
           if (isRecording) recognition.stop();
           else recognition.start();
       }
   </script>
</body>
</html>




"""


# =======================
# FLASK ROUTES
# =======================
@app.route('/')
def index():
   return render_template_string(HTML_PAGE)


@app.route('/process_voice', methods=['POST'])
def web_voice_input():
   data = request.json
   text = data.get('text', '')
   if text:
       process_voice_command(text)
       return jsonify({"status": "processing", "text": text})
   return jsonify({"status": "empty"})


@app.route('/video_feed')
def video_feed():
   return Response(generate_frames(), mimetype='multipart/x-mixed-replace; boundary=frame')


# =======================
# MAIN EXECUTION
# =======================
if __name__ == '__main__':
   print("🚀 STARTING HYBRID SYSTEM (LOCAL MODE)...")
   print("📋 Voice Commands: Maju, Mundur, Berputar, Berhenti, Cari Sampah")


   vision_thread = threading.Thread(target=ai_logic_loop)
   vision_thread.daemon = True
   vision_thread.start()


   try:
       app.run(host='0.0.0.0', port=5000, debug=False, threaded=True)
   finally:
       if picam2: picam2.stop()
       if ser: ser.close()






