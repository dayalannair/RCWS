
# Each thread runs a camera and uRAD USB

import sys
sys.path.append('../custom_modules')

import uRAD_USB_SDK11
import serial
from time import time, sleep, strftime,localtime
import sys
from pyDSPv2 import py_trig_dsp
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
	now = strftime("%H_%M_%S", t)  
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
return_code = uRAD_USB_SDK11.loadConfiguration(ser1, mode, f0, \
	BW, Ns, 0, 0, 0, 0, 0, 0, 0, 0, I_true, Q_true, 0)
if (return_code != 0):
	print("uRAD 1 configuration failed")
	closeProgram()

return_code = uRAD_USB_SDK11.loadConfiguration(ser2, mode, f0, \
	BW, Ns, 0, 0, 0, 0, 0, 0, 0, 0, I_true, Q_true, 0)
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

# Tunable Processing Parameters
n_fft = 1024
half_train = 16
half_guard = 14
Pfa = 1e-4
SOS = Ns*(Pfa**(-1/Ns)-1)
nbins = 32
bin_width = round((n_fft/2)/nbins)
scan_width = 32
calib = 0.9837
twin = signal.windows.taylor(200, nbar=3, sll=100, norm=False)

# frequency axes
fpos = np.linspace(0, round(fs/2)-1, round(n_fft/2))
# negative axis flipped about y axis
fneg = np.linspace(round(fs/n_fft), round(fs/2), round(n_fft/2))

# Fixed parameters
tsweep = 1e-3
slope = BW/tsweep
c = 299792458
rhs_road_width = 1.5
lhs_road_width = 3
angOffsetMinRangeRhs = 100 

# Left radar angle adjustment and correction
angOffsetMinRangeLhs = 7.1 
angOffset = 25*np.pi/180

# DC cancellation
max_voltage = 3.3
ADC_bits = 12
ADC_intervals = 2**ADC_bits
numVoltageLevels = max_voltage/ADC_intervals

# print("Pfa: ", str(Pfa))
# print("CFAR alpha value: ", SOS)
print("System running...")

# ======================= CAMERAS ================================
cap1 = cv2.VideoCapture(0)
cap2 = cv2.VideoCapture(2)

cap1.set(3, 320)
cap1.set(4, 240)

cap2.set(3, 320)
cap2.set(4, 240)

# sleep(0.5)

# ret,frame1 = cap1.read()
# ret,frame2 = cap2.read()

fourcc  = cv2.VideoWriter_fourcc(*'X264')
lhs_vid = cv2.VideoWriter('2thd_lhs_vid_'+now+'_rtproc.avi',fourcc, 20.0, (320,240))
rhs_vid = cv2.VideoWriter('2thd_rhs_vid_'+now+'_rtproc.avi',fourcc, 20.0, (320,240))

# Burst captures expected to be around 30 seconds long
n_rows = 3000
# rg_array = np.zeros([n_rows, nbins], dtype=int)
# sp_array = np.zeros([n_rows, nbins], dtype=int)
# sf_array = np.zeros([n_rows, nbins], dtype=int)

# rg_array_2 = np.zeros([n_rows, nbins], dtype=int)
# sp_array_2 = np.zeros([n_rows, nbins], dtype=int)
# sf_array_2 = np.zeros([n_rows, nbins], dtype=int)

# ----------------------------------------------------------------------------
# THREAD FUNCTION
# ----------------------------------------------------------------------------
def proc_rad_vid(port, fspeed, frange, fsafety, duration, \
		 cap, container, timeStampFileName, angOffsetMinRange, \
			angOffset, rd_width):

	print("uRAD USB processing thread started")
	# Global inputs
	global n_fft
	global twin
	global num_nul
	global half_guard
	global half_train
	global fax
	global bin_width
	global nbins
	global rank
	global numVoltageLevels
	global n_rows
	# Pre-allocated array sizes
	rg_array = np.zeros([n_rows, nbins], dtype=int)
	sp_array = np.zeros([n_rows, nbins], dtype=int)
	sf_array = np.zeros([n_rows, nbins], dtype=int)
	# sp_array_corr= np.zeros([n_rows, nbins], dtype=int)

	# Unsized array - to see how many sweeps were acquired
	# rg_array = []
	# sp_array = []
	# sf_array = []
	i = 0
	timeStampList = []
	t1 = 0
	frames = []
	t0 = time() 
	while (t1<duration):
		return_code, _, raw_results = uRAD_USB_SDK11.detection(port)
		
		if (return_code != 0):
			closeProgram()

		# remember to add the sp_array_corr[i] output to the proc lib
		_,_,_,_,_,_,_,_,rg_array[i], sp_array[i], sf_array[i]  = \
			py_trig_dsp(raw_results[0], raw_results[1], twin, n_fft, \
	       		half_train, half_guard, nbins, bin_width,\
			  	fpos, fneg, SOS, calib, scan_width, angOffsetMinRange,\
				angOffset, numVoltageLevels, rd_width)
		
		i = i + 1

		ret, frame = cap.read()

		if ret==True:
			frames.append(frame)
		else:
			print("Missed video frame: ", timeStampFileName)
			exit()

		# Time stamp for rdr + vid frame
		timeStamp = time()	
		timeStampList.append(timeStamp)
		t1 = timeStamp - t0

	# print("Video capture complete.  Data captured.")
	updateRate = np.average(1/np.ediff1d(timeStampList))
	print("==============================================")
	print("Thread complete: ", timeStampFileName)
	print("----------------------------------------------")
	print("Update rate: ", round(updateRate,4))
	print("Elapsed time: ", str(round(time()-t0,2)))
	print("Radar sweeps processed: ", i)
	print("==============================================")
	
	# Save video data	
	for frame in frames:
		container.write(frame)

	# Save time stamps
	with open(timeStampFileName+'_timeStamps_'+now+'.txt','w') as tfile:
		for item in timeStampList:
			tfile.write(f'{item}\n')

	cap.release()	
	container.release()

	# Save radar results
	np.savetxt(frange, rg_array[0:i, :], fmt='%.2f', delimiter = ' ', newline='\n')
	np.savetxt(fspeed, sp_array[0:i, :], fmt='%.2f', delimiter = ' ', newline='\n')
	np.savetxt(fsafety, sf_array[0:i, :], fmt='%.2f', delimiter = ' ', newline='\n')
	# np.savetxt(fcorr, sf_array[0:i, :], fmt='%.3f', delimiter = ' ', newline='\n')

	
# ----------------------------------------------------------------------------
# END OF THREAD FUNCTION
# ----------------------------------------------------------------------------
lhs_frange = "2thd_lhs_range_results_"+now+".txt"
lhs_fspeed = "2thd_lhs_speed_results_"+now+".txt"
lhs_fsafety = "2thd_lhs_safety_results_"+now+".txt"
# lhs_fcorr = "2thd_lhs_spcorr_results_"+now+".txt"

rhs_frange = "2thd_rhs_range_results_"+now+".txt"
rhs_fspeed = "2thd_rhs_speed_results_"+now+".txt"
rhs_fsafety = "2thd_rhs_safety_results_"+now+".txt"
# rhs_fcorr = "2thd_rhs_spcorr_results_"+now+".txt"

try:
	
	t0 = time()
	t1 = 0

	urad1 = threading.Thread(target=proc_rad_vid, \
		args=[ser1, lhs_fspeed , lhs_frange, lhs_fsafety, duration, \
	 	cap2, lhs_vid, "rtp_lhs", angOffsetMinRangeLhs, angOffset, lhs_road_width])
	urad2 = threading.Thread(target=proc_rad_vid, \
		args=[ser2, rhs_fspeed , rhs_frange, rhs_fsafety, duration, \
		cap1, rhs_vid, "rtp_rhs", angOffsetMinRangeRhs, 0, rhs_road_width])

	t0_proc = time()
	print("==============================================")
	# Start separate threads for each sensor
	urad1.start()
	urad2.start()
	print("==============================================")
	# wait for all threads to finish
	urad1.join()
	urad2.join()

	t1_proc = time()-t0_proc
	t1 = time() - t0
		
	print("Results capture complete.")
	print("==============================================")
	uRAD_USB_SDK11.turnOFF(ser1)
	uRAD_USB_SDK11.turnOFF(ser2)

except KeyboardInterrupt:
	cap1.release()
	cap2.release()
	lhs_vid.release()
	rhs_vid.release()
	uRAD_USB_SDK11.turnOFF(ser1)
	uRAD_USB_SDK11.turnOFF(ser2)
	print("Interrupted.")
	exit()
