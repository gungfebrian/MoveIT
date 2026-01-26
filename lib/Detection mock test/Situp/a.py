##################################################
import cv2
import mediapipe as mp
from PoseModule import poseDetector as PoseDetector
import tkinter.filedialog as fd
from tkinter import *
###################################################
win=Tk()
win.title("Sit up")
width=800
height=800
win.geometry("%dx%d" % (width, height))
mpDraw=mp.solutions.drawing_utils
mpPose=mp.solutions.pose
pose=mpPose.Pose()
detector = PoseDetector()
################################################
def live():
    counter=0
    stage=0
    cap = cv2.VideoCapture(0)
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
                counter +=1
                
        cv2.putText(img,f'{counter}',(10,50),cv2.FONT_HERSHEY_COMPLEX,2,(0,255,255),2) 
        cv2.imshow("Situp",img)  
        if(cv2.waitKey(1) & 0xFF==ord('x')):
            break 
    cap.release()
    cv2.destroyAllWindows()
####################################################
def path_select():
    global explore,cap
    explore = fd.askopenfilename(title='Choose a file of any type', filetypes=[("All files", ".mp4")])# explore = filedialog.askopenfilename()
    
    ######################################
    counter=0
    stage=0
    cap = cv2.VideoCapture(explore)
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
                counter +=1
                
        cv2.putText(img,f'{counter}',(10,50),cv2.FONT_HERSHEY_COMPLEX,2,(0,255,255),2) 
        cv2.imshow("Situp",img)  
        if(cv2.waitKey(1) & 0xFF==ord('x')):
            break 
    cap.release()
    cv2.destroyAllWindows()
    ######################################
#########################################################

def ex():
    win.quit()
##################################################
logo=Label(win, text = "UNIVERSITY OF ENGINEERING AND TECHNOLOGY LAHOR", font = ("Times New Roman", 10))
logo.place(x = 50, y = 15, width=600, height=25) 
##################################################
########################### FOR DEPARTMENT NAME ######################
dep_logo=Label(win, text = "DEPARTMENT : MECHATRONICS AND CONTROL ENGINEERING", font = ("Times New Roman", 10))
dep_logo.place(x = 50, y = 40, width=600, height=25) 
########################### FOR TITLE ######################
sub_logo=Label(win, text = "  CP-2 PROJECT  :           ...SIT UP EXERCISE... ", font = ("Times New Roman", 10))
sub_logo.place(x = 50, y = 65, width=600, height=25)  
########################### LABEL FOR INSTRUCTIONS ######################
sub_logo=Label(win, text = "PLZ CHOOSE THE DIFFRENT OPTIONS ", font = ("Times New Roman", 10))
sub_logo.place(x = 45, y = 450, width=600, height=25)
##########################FOR OPTION TO EXIT THE CAP IMG SCREEN#####################################
sub_logo=Label(win, text = " PRESS X FOR EXIT THE CAP_IMG ", font = ("Times New Roman", 10))
sub_logo.place(x = 55, y = 450, width=600, height=25)
################################################################
explore=Button(win, text= "vedio", font=("Times New Roman",15,"bold","italic"), command=path_select).place(x=350,y=150)
livecam=Button(win, text="Camera",font=("Times New Roman",15,"bold","italic"),command=live).place(x=340,y=250)
close=Button(win, text= "Exit", font=("Times New Roman",15,"bold","italic"), command=ex).place(x=350,y=350)
win.mainloop()