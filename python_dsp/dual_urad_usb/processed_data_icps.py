import sys
sys.path.append('../custom_modules')

import uRAD_USB_SDK11
import serial
from time import time, sleep, strftime,localtime
import sys
from pyDSPv2 import range_speed_safety
import numpy as np
import cv2
from scipy import signal
import threading

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
	# runtime = sweeps*Ns/200000
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
	# print("BW = ",str(BW),"\nNs = ",str(Ns),"\nSweeps = ",str(sweeps))
	# print("Expected run time (saw): ",str(runtime))
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

t_0 = time()

# Generate axes
n_fft = 512
fax = np.linspace(0, round(fs/2), round(n_fft/2))
tsweep = 1e-3
bw = 240e6
slope = bw/tsweep
c = 299792458
rng_ax = c*fax/(2*slope)

# rg_full = np.zeros(16*sweeps)
twin = signal.windows.taylor(200, nbar=3, sll=100, norm=False)
nul_width_factor = 0.04
num_nul = round((n_fft/2)*nul_width_factor)

# CFAR parameters
n_samples = 200
half_guard = n_fft/n_samples
half_guard = int(np.floor(half_guard/2)*2) # make even

half_train = round(20*n_fft/n_samples)
half_train = int(np.floor(half_train/2))
rank = 2*half_train -2*half_guard
# rank = half_train*2
Pfa_expected = 15e-3
# factorial needs integer values

nbins = 16
bin_width = round((n_fft/2)/nbins)

# tsweep = 1e-3
# bw = 240e6
# # can optimise out this calculation
# slope = bw/tsweep
fs = 200e3

print("System running...")

# ======================= CAMERAS ================================
cap1 = cv2.VideoCapture(0)
cap2 = cv2.VideoCapture(2)

cap1.set(3, 176)
cap1.set(4, 144)

cap2.set(3, 176)
cap2.set(4, 144)

sleep(1)


ret,frame1 = cap1.read()
ret,frame2 = cap2.read()

def capture(duration, cap1, cap2):
	# win_factor = 1
	win1 = "Win 1"
	cv2.namedWindow(win1, cv2.WINDOW_NORMAL)    
	# cv2.resizeWindow(win1, win_factor*320, win_factor*240)
	cv2.resizeWindow(win1, 320, 240)
	cv2.moveWindow(win1, 550, 50)  

	win2 = "Win 2"
	cv2.namedWindow(win2, cv2.WINDOW_NORMAL)     
	# cv2.resizeWindow(win2, win_factor*320, win_factor*240)
	cv2.resizeWindow(win2, 320, 240)
	cv2.moveWindow(win2, 900, 50)  
	t0 = time()
	t1 = 0
	print("Video initialised")
	while (t1<duration):
		_,frame1 = cap1.read()
		_,frame2 = cap2.read()
		cv2.imshow(win1,cv2.flip(frame1,0))
		# cv2.imshow(win1,frame1)
		cv2.imshow(win2,frame2)
		cv2.waitKey(1)
		t1 = time() - t0
	cap1.release()	
	cap2.release()

vid1 = threading.Thread(target=capture, args=[duration, cap1, cap2])

n_rows = 4096
rg_array = np.zeros([n_rows, nbins], dtype=int)
sp_array = np.zeros([n_rows, nbins], dtype=int)
sf_array = np.zeros([n_rows, nbins], dtype=int)

rg_array_2 = np.zeros([n_rows, nbins], dtype=int)
sp_array_2 = np.zeros([n_rows, nbins], dtype=int)
sf_array_2 = np.zeros([n_rows, nbins], dtype=int)

def dsp_thread_usb(port, radar_index, i):
	
	# Global inputs
	global n_fft
	global twin
	global num_nul
	global half_guard
	global half_train
	global f_ax
	global bin_width
	global nbins
	global rank

	# Global outputs
	global upth_2
	global dnth_2
	global fftd_2
	global fftu_2

	return_code, _, raw_results = uRAD_USB_SDK11.detection(port)
	if (return_code != 0):
		closeProgram()

	if radar_index == 0:
		rg_array[i], sp_array[i], sf_array[i] = range_speed_safety(raw_results[0], \
			raw_results[1], twin, n_fft, num_nul, half_train, half_guard, rank, nbins, bin_width, f_ax)
	else:
		rg_array_2[i], sp_array_2[i], sf_array_2[i] = range_speed_safety(raw_results[0], \
			raw_results[1], twin, n_fft, num_nul, half_train, half_guard, rank, nbins, bin_width, f_ax)

urad1_index = 0
urad2_index = 1
row_index = 0
frange = "range_results.txt"
fspeed = "speed_results.txt"
fsafet = "safety_results.txt"
# urad1 = threading.Thread(target=dsp_thread_usb, args=[ser1, urad1_index, row_index])
# urad2 = threading.Thread(target=dsp_thread_usb, args=[ser2, urad2_index, row_index])
try:
	vid1.start()
	t0 = time()
	t1 = 0

	while (t1<duration):

		# MUST BE CALLED AGAIN TO RESTART THE THREAD
		urad1 = threading.Thread(target=dsp_thread_usb, args=[ser1, urad1_index, row_index])
		urad2 = threading.Thread(target=dsp_thread_usb, args=[ser2, urad2_index, row_index])

		t0_proc = time()
		
		urad1.start()
		urad2.start()
		urad1.join()
		urad2.join()

		row_index = row_index + 1
		t1_proc = time()-t0_proc
		t1 = time() - t0
		
	vid1.join()
	# vid2.join()
	print("Elapsed time: ", str(time()-t_0))


	np.savetxt(frange, rg_array, fmt='%d', delimiter = ' ', newline='\n')
	np.savetxt(fspeed, sp_array, fmt='%d', delimiter = ' ', newline='\n')
	np.savetxt(fsafet, sf_array, fmt='%d', delimiter = ' ', newline='\n')
	# with open(frange, 'w') as rng, open(fspeed,'w') as spd, \
	# 	open(fsafet,'w') as sft:
		
	# 	for i in range(n_rows):
	# 		rng.write(rg_array[i])
	# 		spd.write(sp_array[i])
	# 		sft.write(sf_array[i])		

	print("Results capture complete.")
	cap1.release()
	cap2.release()
	uRAD_USB_SDK11.turnOFF(ser1)
	uRAD_USB_SDK11.turnOFF(ser2)

except KeyboardInterrupt:
	cap1.release()
	cap2.release()
	uRAD_USB_SDK11.turnOFF(ser1)
	uRAD_USB_SDK11.turnOFF(ser2)
	print("Interrupted.")
	exit()
