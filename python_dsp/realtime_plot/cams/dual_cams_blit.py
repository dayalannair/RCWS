import sys
sys.path.append('../../custom_modules')
from time import sleep
# import matplotlib as mpl
# mpl.rcParams['path.simplify'] = True
# mpl.rcParams['path.simplify_threshold'] = 1.0
# import matplotlib.style as mplstyle
# mplstyle.use(['dark_background', 'ggplot', 'fast'])

import matplotlib.pyplot as plt
import cv2
from matplotlib.gridspec import GridSpec

cap1 = cv2.VideoCapture(0)
cap2 = cv2.VideoCapture(2)

cap1.set(3, 320)
cap1.set(4, 240)

cap2.set(3, 320)
cap2.set(4, 240)

sleep(1)

ret,frame1 = cap1.read()
ret,frame2 = cap2.read()

# fig2, ax2 = plt.subplots(nrows=2, ncols=1, figsize=(3, 4))
# fig2.tight_layout()
# bg2 = fig2.canvas.copy_from_bbox(fig2.bbox)

# ax2[0].imshow(frame1)
# ax2[1].imshow(frame2)
# fig2.canvas.blit(fig2.bbox)


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

try:
	print("Loop running")
	for i in range(200):
		ret1,frame1 = cap1.read()
		ret2,frame2 = cap2.read()
		# fig2.canvas.restore_region(bg2)
		# ax2[0].imshow('frame1',frame1)
		# ax2[1].imshow('frame2',frame2)
		# if ret1:
		cv2.imshow(win1,frame1)
		# cv2.imshow('frame2',frame1)
		# if ret2:
		cv2.imshow(win2,frame2)
		cv2.waitKey(1)
		# sleep(0.1)
		# cv2.imshow('frame2',frame2)
		# fig2.canvas.blit(fig2.bbox)
		# sleep(0.01)
		# fig2.canvas.flush_events()
		
	print("Complete.")
	cap1.release()
	cap2.release()
	
except KeyboardInterrupt:
	cap1.release()
	cap2.release()
	print("Interrupted.")
	exit()
