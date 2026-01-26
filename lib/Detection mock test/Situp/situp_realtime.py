import cv2
import mediapipe as mp
import sys
import os

# Add parent directory to path to import PoseModule
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from PoseModule import poseDetector as PoseDetector

# Initialize MediaPipe and detector
mpDraw = mp.solutions.drawing_utils
mpPose = mp.solutions.pose
pose = mpPose.Pose()
detector = PoseDetector()

# Real-time situp counter
counter = 0
stage = "down"
cap = cv2.VideoCapture(0)

print("Starting real-time situp detection...")
print("Press 'x' to exit")

while True:
    success, img = cap.read()
    if not success:
        print("Failed to read from camera")
        break
    
    # Flip image horizontally for mirror effect
    img = cv2.flip(img, 2)
    
    # Find pose
    img = detector.findPose(img)
    lmlist = detector.findPosition(img, False)
    
    # Process with MediaPipe
    imgRGB = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    results = pose.process(imgRGB)
    
    if results.pose_landmarks:
        points = {}
        for id, lm in enumerate(results.pose_landmarks.landmark):
            h, w, c = img.shape
            cx, cy = int(lm.x * w), int(lm.y * h)
            points[id] = (cx, cy)
        
        # Calculate angle between shoulder, hip, and knee (landmarks 11, 23, 25)
        angle = detector.findAngle(img, 11, 23, 25)
        
        # Situp detection logic
        if angle >= 117 or angle >= 136:
            stage = "down"
        
        if (angle <= 89 or angle <= 102) and stage == 'down':
            stage = "up"
            counter += 1
            print(f"Situp count: {counter}")
    
    # Display counter on screen
    cv2.putText(img, f'Count: {counter}', (10, 50), 
                cv2.FONT_HERSHEY_COMPLEX, 2, (0, 255, 255), 2)
    cv2.putText(img, f'Stage: {stage}', (10, 100), 
                cv2.FONT_HERSHEY_COMPLEX, 1, (0, 255, 0), 2)
    cv2.putText(img, "Press 'x' to exit", (10, img.shape[0] - 20), 
                cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)
    
    cv2.imshow("Situp Counter - Real Time", img)
    
    if cv2.waitKey(1) & 0xFF == ord('x'):
        break

cap.release()
cv2.destroyAllWindows()
print(f"Final situp count: {counter}")
