from tkinter.font import nametofont
import cv2
from imutils.video import VideoStream
from time import sleep
import threading

cap1 = cv2.VideoCapture(0)
cap2 = cv2.VideoCapture(2)
sleep(1)
# # Define the codec and create VideoWriter object
fourcc = cv2.VideoWriter_fourcc(*'X264')
out1 = cv2.VideoWriter('output1.avi',fourcc, 20.0, (640,480))
out2 = cv2.VideoWriter('output2.avi',fourcc, 20.0, (640,480))

def capture(n, cap, out):
    for i in range (n):
        ret, frame = cap.read()
        if ret==True:
            out.write(frame)
        print(i)
	
n_frames = 50
vid1 = threading.Thread(target=capture, args=(n_frames, cap1, out1))
vid2 = threading.Thread(target=capture, args=(n_frames, cap2, out2))
vid1.start()
vid2.start()

print("Waiting for threads to finish...")
vid1.join()
vid2.join()
print("Complete.")
# 

# ========= NON THREADED ====================
# for i in range (100):
#     ret, frame1 = cap1.read()
#     ret, frame2 = cap2.read()
#     if ret==True:
#         out1.write(frame1)
#         out2.write(frame2)   
#         # cv2.imshow('frame',frame1)
#         # cv2.imshow('frame',frame2)
#         # if cv2.waitKey(1) & 0xFF == ord('q'):
#         #     break

#         print(i)
#     else:
#         break
# ==========================================
# Release everything if job is finished
cap1.release()
cap2.release()
out1.release()
out2.release()
cv2.destroyAllWindows()


# print("[INFO] starting cameras...")
# cam1 = VideoStream(src=0).start()
# cam2 = VideoStream(src=-1).start()
# sleep(2.0)

# initialize the list of frames that have been processed
# frames = []

# for i in range(1000):
#     frame = stream.r
    



