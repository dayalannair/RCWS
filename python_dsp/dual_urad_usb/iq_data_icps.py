import sys
sys.path.append('../custom_modules')
import uRAD_USB_SDK11
import serial
from time import time, sleep, strftime,localtime
import cv2
import threading


# True if USB, False if UART
usb_communication = True

try:
	mode_in = str(sys.argv[1])
	BW = int(sys.argv[2])
	Ns = int(sys.argv[3])
	duration = int(sys.argv[4])
	t = localtime()
	now = strftime("%H_%M_%S", t)  
	fs = 200000
	if mode_in == "s":
		print("********** SAWTOOTH MODE **********")
		resultsFileName = 'IQ_saw_' + str(BW) + '_' + str(Ns) +  '_' + str(now) + '.txt'
		mode = 2					
	elif mode_in == "t":
		print("********** TRIANGLE MODE **********")
		resultsFileName = 'IQ_tri_' + str(BW) + '_' + str(Ns) + '_' + str(now) + '.txt'
		mode = 3	
	elif mode_in == "d":
		print("********** DUAL RATE MODE **********")
		resultsFileName = 'IQ_dual_' + str(BW) + '_' + str(Ns) + '_' + str(now) + '.txt'
		mode = 4					
	else: 
		print("Invalid mode")
		exit()
	print("BW = ",str(BW),"\nNs = ",str(Ns),"\nSweeps = ",str(duration))
	print("Duration: ",str(duration), 's')
except: 
	print("Invalid mode")
	exit()

# input parameters
# BW and Ns input as arguments
f0 = 5						# starting at 24.005 GHz
I_true = True 				# In-Phase Component (RAW data) requested
Q_true = True 				# Quadrature Component (RAW data) requested

# Serial Port configuration
ser1 = serial.Serial()
if (usb_communication):
	# ser1.port = 'COM3'
	ser1.port = '/dev/ttyACM0'
	ser1.baudrate = 1e6
else:
	print("Could not find USB 1 connection.")
	exit()

ser2 = serial.Serial()
if (usb_communication):
	# ser1.port = 'COM3'
	ser2.port = '/dev/ttyACM1'
	ser2.baudrate = 1e6
else:
	print("Could not find USB 2 connection.")
	exit()

# Sleep Time (seconds) between iterations
timeSleep = 5e-3

# Other serial parameters
ser1.bytesize = serial.EIGHTBITS
ser1.parity = serial.PARITY_NONE
ser1.stopbits = serial.STOPBITS_ONE
ser1.timeout = 1

ser2.bytesize = serial.EIGHTBITS
ser2.parity = serial.PARITY_NONE
ser2.stopbits = serial.STOPBITS_ONE
ser2.timeout = 1

# Method to correctly turn OFF and close uRAD
def closeProgram():
	# switch OFF uRAD
	return_code1 = uRAD_USB_SDK11.turnOFF(ser1)
	return_code2 = uRAD_USB_SDK11.turnOFF(ser2)
	if (return_code1 != 0 or return_code2 != 0):
		print("ERROR: Ending")
		exit()

# Open serial port
try:
	ser1.open()
except:
	print("COM port 1 failed to open")
	closeProgram()

try:
	ser2.open()
except:
	print("COM port 2 failed to open")
	closeProgram()


# switch ON uRAD
return_code = uRAD_USB_SDK11.turnON(ser1)
if (return_code != 0):
	print("uRAD 1 failed to turn on")
	closeProgram()

return_code = uRAD_USB_SDK11.turnON(ser2)
if (return_code != 0):
	print("uRAD 2 failed to turn on")
	closeProgram()


if (not usb_communication):
	sleep(timeSleep)

# loadConfiguration uRAD
return_code = uRAD_USB_SDK11.loadConfiguration(ser1, mode, f0, BW, Ns, 0, 0, 0, 0, 0, 0, 0, 0, I_true, Q_true, 0)
if (return_code != 0):
	print("uRAD 1 configuration failed")
	closeProgram()

return_code = uRAD_USB_SDK11.loadConfiguration(ser2, mode, f0, BW, Ns, 0, 0, 0, 0, 0, 0, 0, 0, I_true, Q_true, 0)
if (return_code != 0):
	print("uRAD 2 configuration failed")
	closeProgram()

if (not usb_communication):
	sleep(timeSleep)

# Poll radar to test if working correctly
return_code, results, raw_results = uRAD_USB_SDK11.detection(ser1)
if (return_code != 0):
	print("Error requesting data from uRAD 1")
	closeProgram()

return_code, results, raw_results = uRAD_USB_SDK11.detection(ser2)
if (return_code != 0):
	print("Error requesting data from uRAD 2")
	closeProgram()

print("Radars configured. Initialising threads...")
#=============================================================
# 						Cameras
# ============================================================
cap1 = cv2.VideoCapture(0)
cap2 = cv2.VideoCapture(2)

cap1.set(3, 320)
cap1.set(4, 240)

cap2.set(3, 320)
cap2.set(4, 240)

sleep(1)
# # Define the codec and create VideoWriter object
fourcc = cv2.VideoWriter_fourcc(*'X264')
out1 = cv2.VideoWriter('rhs_vid_'+now+'.avi',fourcc, 20.0, (320,240))
out2 = cv2.VideoWriter('lhs_vid_'+now+'.avi',fourcc, 20.0, (320,240))

# Camera thread function
def capture(duration, cap, out):
	print("Video thread runnning...")
	frames = []
	t0 = time()
	t1 = 0
	while (t1 < duration):
		ret, frame = cap.read()
		
		if ret==True:
			frames.append(frame)
		
		t1 = time() - t0

	print("Video recorded with duration ", str(t1))
	for frame in frames:
		out.write(frame)

# Camera threads
vid1 = threading.Thread(target=capture, args=[duration, cap1, out1])
vid2 = threading.Thread(target=capture, args=[duration, cap2, out2])

# ================================================================
# 							uRAD thread
# ================================================================
def urad_capture(duration, fname, port):
	print("uRAD USB thread running...")
	I_usb = []
	Q_usb = []
	t0 = time()
	t1 = 0

	# Capture data
	while (t1 < duration):
		return_code, results, raw_results = uRAD_USB_SDK11.detection(port)
		if (return_code != 0):
			closeProgram()

		I_usb.append(raw_results[0])
		Q_usb.append(raw_results[1])

		t1 = time() - t0

	# Store data
	sweeps = len(I_usb)
	print("uRAD USB data recorded with duration ", str(t1))
	print("Sweeps acquired: ", sweeps)
	print("uRAD USB storing data...")
	up_down_length = len(I_usb[0])
	with open(fname, 'w') as usb:
		for sweep in range(sweeps):
			IQ_usb = ''
			# Length is 2*Ns
			# Store I data
			for sample in range(up_down_length):
				IQ_usb += '%d ' % I_usb[sweep][sample]
			# Store Q data
			for sample in range(up_down_length):
				IQ_usb += '%d ' % Q_usb[sweep][sample]
			usb.write(IQ_usb + '\n')
	print("uRAD USB capture complete.")

# Separate files for each radar
urad1_fname = "lhs_iq_"+now+".txt"
urad2_fname = "rhs_iq_"+now+".txt"

# uRAD threads
urad1 = threading.Thread(target=urad_capture, args=[duration, urad1_fname, ser1])
urad2 = threading.Thread(target=urad_capture, args=[duration, urad2_fname, ser2])

try:
	t_0 = time()
	# Start camera threads
	vid1.start()
	vid2.start()
	urad1.start()
	urad2.start()

	# Wait for cameras to finish recording
	vid1.join()
	vid2.join()
	urad1.join()
	urad2.join()

	print("Elapsed time: ", str(time()-t_0))
	
	cap1.release()
	cap2.release()
	out1.release()
	out2.release()
	uRAD_USB_SDK11.turnOFF(ser1)
	uRAD_USB_SDK11.turnOFF(ser2)
	print("Complete.")
	
except KeyboardInterrupt:
	cap1.release()
	cap2.release()
	out1.release()
	out2.release()
	uRAD_USB_SDK11.turnOFF(ser1)
	uRAD_USB_SDK11.turnOFF(ser2)
	print("Interrupted.")
	exit()
