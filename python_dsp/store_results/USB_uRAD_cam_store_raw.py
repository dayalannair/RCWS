import sys
sys.path.append('../python_modules')
import uRAD_USB_SDK11
import serial
from time import time, sleep, strftime,localtime
import cv2

# True if USB, False if UART
usb_communication = True

try:
	mode_in = str(sys.argv[1])
	BW = int(sys.argv[2])
	Ns = int(sys.argv[3])
	sweeps = int(sys.argv[4])
	t = localtime()
	now = strftime("%H-%M-%S", t)  
	fs = 200000
	runtime = sweeps*Ns/200000
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
	print("BW = ",str(BW),"\nNs = ",str(Ns),"\nSweeps = ",str(sweeps))
	print("Expected run time (saw): ",str(runtime))
except: 
	print("Invalid mode")
	exit()

# input parameters
# BW and Ns input as arguments
f0 = 5						# starting at 24.005 GHz
I_true = True 				# In-Phase Component (RAW data) requested
Q_true = True 				# Quadrature Component (RAW data) requested

# Serial Port configuration
ser = serial.Serial()
if (usb_communication):
	# ser.port = 'COM3'
	ser.port = '/dev/ttyACM0'
	ser.baudrate = 1e6
else:
	print("Could not find USB connection.")
	exit()
	# ser.port = '/dev/serial0'
	# ser.baudrate = 115200

# Sleep Time (seconds) between iterations
timeSleep = 5e-3

# Other serial parameters
ser.bytesize = serial.EIGHTBITS
ser.parity = serial.PARITY_NONE
ser.stopbits = serial.STOPBITS_ONE
ser.timeout = 1

# Method to correctly turn OFF and close uRAD
def closeProgram():
	# switch OFF uRAD
	return_code = uRAD_USB_SDK11.turnOFF(ser)
	if (return_code != 0):
		print("ERROR: Ending")
		exit()

# Open serial port
try:
	ser.open()
except:
	print("COM port failed to open")
	closeProgram()

# switch ON uRAD
return_code = uRAD_USB_SDK11.turnON(ser)
if (return_code != 0):
	print("uRAD failed to turn on")
	closeProgram()

if (not usb_communication):
	sleep(timeSleep)

# loadConfiguration uRAD
return_code = uRAD_USB_SDK11.loadConfiguration(ser, mode, f0, BW, Ns, 0, 0, 0, 0, 0, 0, 0, 0, I_true, Q_true, 0)
if (return_code != 0):
	print("uRAD configuration failed")
	closeProgram()

if (not usb_communication):
	sleep(timeSleep)

I_usb = []
Q_usb = []

t_0 = time()

return_code, results, raw_results = uRAD_USB_SDK11.detection(ser)
if (return_code != 0):
	closeProgram()

cap1 = cv2.VideoCapture(0)
fourcc = cv2.VideoWriter_fourcc(*'X264')
# 20 fps = 1 frame every 5ms which seems inline with urad update rate (VERIFY)
cam1_vid = cv2.VideoWriter('cam1_vid.avi',fourcc, 20.0, (640,480))

print("System running...")

PifileName = "IQ_pi.txt"
USBfileName = "IQ_usb.txt"
try:
	for i in range(sweeps):
		# fetch IQ from uRAD USB
		return_code, results, raw_results = uRAD_USB_SDK11.detection(ser)
		if (return_code != 0):
			closeProgram()
			
		I_usb.append(raw_results[0])
		Q_usb.append(raw_results[1])

		ret, lhs_frame = cap1.read()
		cam1_vid.write(lhs_frame)


	print("Elapsed time: ", str(time()-t_0))
	print("Saving data...")
	with open(PifileName, 'w') as rpi, open(USBfileName, 'w') as usb:
		for sweep in range(sweeps):
			IQ_rpi = ''
			IQ_usb = ''
			# Length is 2*Ns
			up_down_length = len(I_usb[0])
			# Store I data
			for sample in range(up_down_length):
				IQ_usb += '%d ' % I_usb[sweep][sample]
			# Store Q data
			for sample in range(up_down_length):
				IQ_usb += '%d ' % Q_usb[sweep][sample]
			#f.write(IQ_string + '%1.3f\n' % t_i[sweep])
			rpi.write(IQ_rpi + '\n')
			usb.write(IQ_usb + '\n')

	cap1.release()
	cam1_vid.release()
	uRAD_USB_SDK11.turnOFF(ser)
	print("Complete.")
	
except KeyboardInterrupt:
	uRAD_USB_SDK11.turnOFF(ser)
	print("Interrupted.")
	exit()
