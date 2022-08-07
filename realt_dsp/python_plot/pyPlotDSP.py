import uRAD_USB_SDK11
import serial
from time import time, sleep, strftime,localtime
import sys
from pyDSP import py_trig_dsp
from datetime import datetime
import numpy as np
import matplotlib.pyplot as plt
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
	ser.port = 'COM3'
	# ser.port = '/dev/ttyACM0'
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

t_0 = time()
i = 0
I = []
Q = []

# ------------------------ Frequency axis -----------------
nfft = 512
# kHz Axis
fax = np.linspace(0, round(fs/2), round(nfft/2))
# c*fb/(2*slope)
tsweep = 1e-3
bw = 240e6
slope = bw/tsweep
c = 3e8
rng_ax = c*fax/(2*slope)
return_code, results, raw_results = uRAD_USB_SDK11.detection(ser)
if (return_code != 0):
	closeProgram()
		# I.append(raw_results[0])
		# Q.append(raw_results[1])
		# call matlab dsp
I = raw_results[0]
Q = raw_results[1]
cfar_res_up, cfar_res_dn, upth, dnth, fftu, fftd = py_trig_dsp(I,Q)
plt.ion()
# x = np.zeros(100, 100)
# y = np.zeros(100, 100)
figure, ax = plt.subplots(nrows=2, ncols=1, figsize=(10, 8))
line1, = ax[0].plot(rng_ax, fftu)
line2, = ax[0].plot(rng_ax, upth)
line3, = ax[1].plot(rng_ax, fftd)
line4, = ax[1].plot(rng_ax, dnth)
# CFAR stems
# line5, = ax[0].stem([],cfar_res_up)
# line6, = ax[1].stem([],cfar_res_dn)
print(len(rng_ax))
line5, = ax[0].plot(rng_ax, cfar_res_up, markersize=20)
line6, = ax[1].plot(rng_ax, cfar_res_dn, markersize=20)

print(cfar_res_dn)
# eng.eval("load(\'urad_trig_proc_config.mat\')")
print("System running...")
try:
	for i in range(sweeps):
		return_code, results, raw_results = uRAD_USB_SDK11.detection(ser)
		if (return_code != 0):
			closeProgram()
		# I.append(raw_results[0])
		# Q.append(raw_results[1])
		# call matlab dsp
		I = raw_results[0]
		Q = raw_results[1]
		t0_proc = time()
		cfar_res_up, cfar_res_dn, upth, dnth, fftu, fftd = py_trig_dsp(I,Q)
		t1_proc = time()-t0_proc
		# print(len(cfar_res_up))
		line1.set_ydata(fftu)
		line2.set_ydata(upth)
		line3.set_ydata(fftd)
		line4.set_ydata(dnth)
		line5.set_ydata(cfar_res_up)
		line6.set_ydata(cfar_res_dn)
		# print(cfar_res_dn)
		figure.canvas.draw()
		# sleep(0.5)
		figure.canvas.flush_events()
		# plt.plot(fftu)
		# plt.show()
		# sleep(1)
		# plot1.set_xdata(x)
		# plot1.set_ydata(update_y_value)
	
		# figure.canvas.draw()
		# figure.canvas.flush_events()

		# print("Processing time: ", t1_proc)
		# if eng.workspace['safety']<10:
		# 	print("Range of hazardous target: ", eng.workspace['targ_rng'])
		# 	print("Speed of hazardous target: ", eng.workspace['targ_vel'])
		# 	print("TOA of hazardous target: ", eng.workspace['safety'])
		

	print("Elapsed time: ", str(time()-t_0))

	print("Complete.")
	
except KeyboardInterrupt:
	uRAD_USB_SDK11.turnOFF(ser)
	print("Interrupted.")
	exit()
