import sys
sys.path.append('../python_modules')
import uRAD_USB_SDK11
import uRAD_RP_SDK10		# uRAD v1.1 RPi lib
import serial
from time import time, sleep, strftime,localtime
import threading
import matplotlib.pyplot as plt
import numpy as np
# True if USB, False if UART
usb_communication = True

try:
	mode_in = str(sys.argv[1])
	BW = int(sys.argv[2])
	Ns = int(sys.argv[3])
	duration = int(sys.argv[4])
	t = localtime()
	now = strftime("%H-%M-%S", t)  
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
#Switch on Pi uRAD
uRAD_RP_SDK10.turnON()
# no return code from SDK 1.0 for RPi
uRAD_RP_SDK10.loadConfiguration(mode, f0, BW, Ns, 0, 0, 0, 0)

return_code, results, raw_results = uRAD_USB_SDK11.detection(ser)
if (return_code != 0):
	closeProgram()


plt.ion()
figure, ax = plt.subplots(nrows=2, ncols=2, figsize=(10, 8))


ax[0].set_title("USB Down chirp spectrum negative half flipped")
ax[0].set_xlabel("Coupled Range (m)")
ax[0].set_ylabel("Magnitude (dB)")
ax[1].set_title("USB Up chirp spectrum positive half")
ax[1].set_xlabel("Coupled Range (m)")
ax[1].set_ylabel("Magnitude (dB)")
ax[2].set_title("RPI Down chirp spectrum negative half flipped")
ax[3].set_title("RPI Up chirp spectrum positive half")
ax[2].set_xlabel("Coupled Range (m)")
ax[3].set_xlabel("Coupled Range (m)")
ax[2].set_ylabel("Magnitude (dB)")
ax[3].set_ylabel("Magnitude (dB)")	


print("System running...")
# ================================================================
# 							uRAD threads
# ================================================================
def rpi_urad_capture(duration):
	print("uRAD RPI thread running...")
	
	Q_temp = [0] * 2 * Ns
	I_temp = [0] * 2 * Ns
	I_rpi = []
	Q_rpi = []

	line1, = ax[0].plot()
	line1, = ax[1].plot()

	t0 = time()
	t1 = 0

	# Capture data
	while (t1 < duration):
		uRAD_RP_SDK10.detection(0, 0, 0, I_temp, Q_temp, 0)
		I_rpi.append(I_temp[:])
		Q_rpi.append(Q_temp[:])

		t1 = time() - t0

		line1.set_ydata(np.fft())
		line2.set_ydata(upth)

		
	sweeps = len(I_rpi)
	# Store results
	print("uRAD RPI data recorded with duration ", str(t1))
	print("uRAD RPI storing data...")
	with open("IQ_pi.txt", 'w') as rpi:
		for sweep in range(sweeps):
			IQ_rpi = ''
			# Length is 2*Ns
			up_down_length = len(I_rpi[0])
			# Store I data
			for sample in range(up_down_length):
				IQ_rpi += '%d ' % I_rpi[sweep][sample]
			# Store Q data
			for sample in range(up_down_length):
				IQ_rpi += '%d ' % Q_rpi[sweep][sample]
			#f.write(IQ_string + '%1.3f\n' % t_i[sweep])
			rpi.write(IQ_rpi + '\n')
	print("uRAD RPI capture complete.")

def usb_urad_capture(duration):
	print("uRAD USB thread running...")
	I_usb = []
	Q_usb = []
	t0 = time()
	t1 = 0
	line2, = ax[0].plot()
	# Capture data
	while (t1 < duration):
		return_code, results, raw_results = uRAD_USB_SDK11.detection(ser)
		if (return_code != 0):
			closeProgram()

		I_usb.append(raw_results[0])
		Q_usb.append(raw_results[1])

		t1 = time() - t0

	# Store data
	sweeps = len(I_usb)
	print("uRAD USB data recorded with duration ", str(t1))
	print("uRAD USB storing data...")
	up_down_length = len(I_usb[0])
	with open("IQ_usb.txt", 'w') as usb:
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

# uRAD threads
rpi_urad = threading.Thread(target=rpi_urad_capture, args=[duration])
usb_urad = threading.Thread(target=usb_urad_capture, args=[duration])

try:
	t_0 = time()
	# Start camera threads
	rpi_urad.start()
	usb_urad.start()
	

	# NON threaded uRAD detection
	# Start uRADs
	# for i in range(duration):
	# 	# fetch IQ from uRAD Pi
	# 	uRAD_RP_SDK10.detection(0, 0, 0, I_temp, Q_temp, 0)
	# 	# fetch IQ from uRAD USB
	# 	return_code, results, raw_results = uRAD_USB_SDK11.detection(ser)
	# 	if (return_code != 0):
	# 		closeProgram()
			
	# 	I_usb.append(raw_results[0])
	# 	Q_usb.append(raw_results[1])

	# 	I_rpi.append(I_temp[:])
	# 	Q_rpi.append(Q_temp[:])

	# Wait for cameras to finish recording
	rpi_urad.join()
	usb_urad.join()
	# print(I_usb)
	print("Elapsed time: ", str(time()-t_0))
	# print("Saving data...")
	# with open(PifileName, 'w') as rpi, open(USBfileName, 'w') as usb:
	# 	for sweep in range(duration):
	# 		IQ_rpi = ''
	# 		IQ_usb = ''
	# 		# Length is 2*Ns
	# 		up_down_length = len(I_usb[0])
	# 		# Store I data
	# 		for sample in range(up_down_length):
	# 			IQ_rpi += '%d ' % I_rpi[sweep][sample]
	# 			IQ_usb += '%d ' % I_usb[sweep][sample]
	# 		# Store Q data
	# 		for sample in range(up_down_length):
	# 			IQ_rpi += '%d ' % Q_rpi[sweep][sample]
	# 			IQ_usb += '%d ' % Q_usb[sweep][sample]
	# 		#f.write(IQ_string + '%1.3f\n' % t_i[sweep])
	# 		rpi.write(IQ_rpi + '\n')
	# 		usb.write(IQ_usb + '\n')

	cap1.release()
	cap2.release()
	out1.release()
	out2.release()
	uRAD_RP_SDK10.turnOFF()
	uRAD_USB_SDK11.turnOFF(ser)
	print("Complete.")
	
except KeyboardInterrupt:
	cap1.release()
	cap2.release()
	out1.release()
	out2.release()
	uRAD_RP_SDK10.turnOFF()
	uRAD_USB_SDK11.turnOFF(ser)
	print("Interrupted.")
	exit()
