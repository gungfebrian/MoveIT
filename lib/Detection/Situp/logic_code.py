import cv2
from PoseModule import poseDetector
import mediapipe as mp

mpDraw=mp.solutions.drawing_utils
mpPose=mp.solutions.pose
pose=mpPose.Pose()
detector = poseDetector()
###################################################
cap = cv2.VideoCapture('SitUp.mp4')
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1350)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 650)
counter=0
stage=0
####################################################
while True:
    success, img = cap.read()
    img=cv2.flip(img, 2)
    img = detector.findPose(img)
    lmlist=detector.findPosition(img,False)
    imgRGB=cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    results=pose.process(imgRGB)
    # detector.findPosition(img, bboxWithHands=False)
    if results.pose_landmarks:
        # mpDraw.draw_landmarks(img, results.pose_landmarks,mpPose.POSE_CONNECTIONS)
        points={}
        for id, lm in enumerate(results.pose_landmarks.landmark):
            h,w,c=img.shape
            cx,cy=int(lm.x*w),int(lm.y*h)
            points[id]=(cx,cy)
        angle=detector.findAngle(img,11,23,25)         
        if angle >= 117 or angle >= 136:
                stage = "down"

        if (angle <= 89 or angle <= 102) and stage =='down':
            stage="up"
            print(stage)
            counter +=1
            print(counter)
            
        if counter==3:
            print('your task will be completed')
            break   
        
####################################################    
        
    cv2.imshow("Image", img)
    cv2.waitKey(1)
####################################################
