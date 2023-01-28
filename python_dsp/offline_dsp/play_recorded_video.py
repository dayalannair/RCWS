import numpy as np
import sys
import cv2
sys.path.append('../custom_modules')
from load_data_lib import load_video
import sys
sys.path.append("C:\\Users\\naird\\OneDrive - University of Cape Town\\RCWS_DATA\\road_data_03_11_2022\\iq_vid")


# f_lhs_vid, f_rhs_vid = load_video()
f_lhs_vid = "C:\\Users\\naird\\OneDrive - University of Cape Town\\RCWS_DATA\\road_data_03_11_2022\\iq_vid\\lhs_vid_12_18_12.avi"
print('LHS vid name: ', f_lhs_vid)


cap1 = cv2.VideoCapture(f_lhs_vid)

cap1.set(3, 320)
cap1.set(4, 240)

win1 = "Win 1"
cv2.namedWindow(win1, cv2.WINDOW_NORMAL)        # Create a named window
cv2.resizeWindow(win1, 200, 200)
cv2.moveWindow(win1, 0,0)  # Move it to (40,30)
# cv2.namedWindow(win1)        # Create a named window
# cv2.moveWindow(win1, 60,30)  # Move it to (40,30)

win2 = "Win 2"
cv2.namedWindow(win2, cv2.WINDOW_NORMAL)        # Create a named window
cv2.resizeWindow(win2, 200, 200)
cv2.moveWindow(win2, 0,200)  # Move it to (40,30)


# time_length = 30.0
# fps=25
# frame_seq = 749
# frame_no = (frame_seq /(time_length*fps))

# cap.set(2,frame_no)

for i in range(100):

    ret, frame = cap1.read()
    cv2.imshow(win1, frame)

    cv2.waitKey(1)


cap1.release()
cv2.destroyAllWindows()