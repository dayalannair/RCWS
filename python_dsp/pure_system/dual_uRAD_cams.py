import uRAD_USB_SDK11
import uRAD_RP_SDK10		# uRAD v1.1 RPi lib
import serial
from time import time, sleep, strftime,localtime
import sys
from pyDSPv2 import py_trig_dsp
import numpy as np
# import matplotlib
# matplotlib.use('Agg')
import matplotlib.pyplot as plt
import cv2
from matplotlib.gridspec import GridSpec
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
#Switch on Pi uRAD
uRAD_RP_SDK10.turnON()
# no return code from SDK 1.0 for RPi
uRAD_RP_SDK10.loadConfiguration(mode, f0, BW, Ns, 0, 0, 0, 0)

I_pi = [0] * 2 * Ns
Q_pi = [0] * 2 * Ns
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
rg_full = np.zeros(16*sweeps)
os_pku, os_pkd, upth, dnth, fftu, fftd, safet, beat_index, beat_min,rg_array, sp_array = py_trig_dsp(I,Q)
plt.ion()
print(beat_index)
print(beat_min)

upth = 20*np.log(upth)
dnth = 20*np.log(dnth)
fftu = 20*np.log(abs(fftu))
fftd = 20*np.log(abs(fftd))
os_pku = 20*np.log(abs(os_pku))
os_pkd = 20*np.log(abs(os_pkd))


# x = np.zeros(100, 100)
# y = np.zeros(100, 100)

# fig = plt.figure()
# gs = GridSpec(4, 2, wspace=0.4, hspace=0.3, figure=fig)

# ax1 = fig.add_subplot(gs[0, 0])
# ax2 = fig.add_subplot(gs[1, 0])
# ax3 = fig.add_subplot(gs[2, 0])
# ax4 = fig.add_subplot(gs[3, 0])

# ax5 = fig.add_subplot(gs[0:1, 1])
# ax6 = fig.add_subplot(gs[2:3, 1])

fig, ax = plt.subplots(nrows=4, ncols=2, figsize=(10, 8))
line1, = ax[0, 0].plot(rng_ax, fftu)
line2, = ax[0, 0].plot(rng_ax, upth)
line3, = ax[1, 0].plot(rng_ax, fftd)
line4, = ax[1, 0].plot(rng_ax, dnth)

ax[0, 0].set_title("USB Down chirp spectrum negative half flipped")
ax[1, 0].set_title("USB Up chirp spectrum positive half")

ax[0, 0].set_xlabel("Coupled Range (m)")
ax[1, 0].set_xlabel("Coupled Range (m)")

ax[0, 0].set_ylabel("Magnitude (dB)")
ax[1, 0].set_ylabel("Magnitude (dB)")


line1_pi, = ax[2, 0].plot(rng_ax, fftu)
line2_pi, = ax[2, 0].plot(rng_ax, upth)
line3_pi, = ax[3, 0].plot(rng_ax, fftd)
line4_pi, = ax[3, 0].plot(rng_ax, dnth)

ax[2, 0].set_title("RPI Down chirp spectrum negative half flipped")
ax[3, 0].set_title("RPI Up chirp spectrum positive half")

ax[2, 0].set_xlabel("Coupled Range (m)")
ax[3, 0].set_xlabel("Coupled Range (m)")

ax[2, 0].set_ylabel("Magnitude (dB)")
ax[3, 0].set_ylabel("Magnitude (dB)")



# CFAR stems
# line5, = ax[0].stem([],cfar_res_up)
# line6, = ax[1].stem([],cfar_res_dn)
# line5, = ax[0, 0].plot(rng_ax, os_pku, markersize=20)
# line6, = ax[1, 0].plot(rng_ax, os_pkd, markersize=20)

# line7, = ax[2].plot(rg_full)
# line8, = ax[3].plot(sp_array)

# ax[1].axvline(rng_ax[beat_index])
# ax[1].axvline(rng_ax[beat_min])
# print(cfar_res_dn)
# eng.eval("load(\'urad_trig_proc_config.mat\')")
print("System running...")
safety_inv = np.zeros(sweeps)
safety_inv_pi = np.zeros(sweeps)


# ****************** CAMERAS ***********************
def grab_frame(cap):
	ret,frame = cap.read()
	# return cv2.cvtColor(frame,cv2.COLOR_BGR2RGB)
	return frame
cap1 = cv2.VideoCapture(0)
# cap2 = cv2.VideoCapture(1)
fig2, ax2 = plt.subplots(nrows=2, ncols=1, figsize=(10, 8))
im1 = ax2[0].imshow(grab_frame(cap1))
# im2 = ax2[1].imshow(grab_frame(cap2))
# im1 = ax[0, 1].imshow(grab_frame(cap1))
# im2 = ax2.imshow(grab_frame(cap2))

try:
	for i in range(sweeps):
		ret1,frame1 = cap1.read()
		im1.set_data(grab_frame(cap1))
		# ret2,frame2 = cap2.read()
		# im2.set_data(grab_frame(cap2))
		return_code, results, raw_results = uRAD_USB_SDK11.detection(ser)
		if (return_code != 0):
			closeProgram()
		uRAD_RP_SDK10.detection(0, 0, 0, I_pi, Q_pi, 0)
		# print(I_pi)
		# sleep(10)
		# I.append(raw_results[0])
		# Q.append(raw_results[1])
		# call matlab dsp
		I = raw_results[0]
		Q = raw_results[1]
		t0_proc = time()
		os_pku, os_pkd, upth, dnth, fftu, fftd, safety_inv[i], beat_index, beat_min, rg_array, sp_array = py_trig_dsp(I,Q)
		os_pku_pi, os_pkd_pi, upth_pi, dnth_pi, fftu_pi, fftd_pi, safety_inv_pi[i], beat_index_pi, beat_min_pi, rg_array_pi, sp_array_pi = py_trig_dsp(I_pi,Q_pi)
		np.concatenate((rg_full, rg_array))
		rg_full[i*16:(i+1)*16] = rg_array
		print(safety_inv[i])
		t1_proc = time()-t0_proc

		upth = 20*np.log(upth)
		dnth = 20*np.log(dnth)
		fftu = 20*np.log(abs(fftu))
		fftd = 20*np.log(abs(fftd))
		os_pku = 20*np.log(abs(os_pku))
		os_pkd = 20*np.log(abs(os_pkd))

		upth_pi = 20*np.log(upth_pi)
		dnth_pi = 20*np.log(dnth_pi)
		fftu_pi = 20*np.log(abs(fftu_pi))
		fftd_pi = 20*np.log(abs(fftd_pi))

		# print(len(cfar_res_up))

		# ax1.plot(fftu)
		# ax2.plot(upth)
		# ax3.plot(fftd)
		# ax4.plot(dnth)

		
		# line2.set_ydata(upth)
		# line3.set_ydata(fftd)
		# line4.set_ydata(dnth)
		# line5.set_ydata(os_pku)
		# line6.set_ydata(os_pkd)

		# line1_pi.set_ydata(fftu_pi)
		# line2_pi.set_ydata(upth_pi)
		# line3_pi.set_ydata(fftd_pi)
		# line4_pi.set_ydata(dnth_pi)


		# line1.set_ydata(fftu)
		# line2.set_ydata(upth)
		# line3.set_ydata(fftd)
		# line4.set_ydata(dnth)
		# line5.set_ydata(os_pku)
		# line6.set_ydata(os_pkd)

		# line1_pi.set_ydata(fftu_pi)
		# line2_pi.set_ydata(upth_pi)
		# line3_pi.set_ydata(fftd_pi)
		# line4_pi.set_ydata(dnth_pi)


		# line9 = ax[1, 0].axvline(rng_ax[beat_index])
		# line10 = ax[1, 0].axvline(rng_ax[beat_min])
		# line9.remove()
		# line10.remove()
		
		# print(cfar_res_dn)
		# TRY THE BELOW:
		# ani = FuncAnimation(plt.gcf(), update, interval=200)
		# plt.show()
		fig.canvas.draw()
		fig.savefig('temp1.jpeg')
		# ax[1].clear()
		# sleep(0.5)
		fig.canvas.flush_events()

		fig2.canvas.draw()
		fig2.savefig('temp2.jpeg')
		# ax[1].clear()
		# sleep(0.5)
		fig2.canvas.flush_events()
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
	uRAD_RP_SDK10.turnOFF()
	uRAD_USB_SDK11.turnOFF(ser)
	print("Interrupted.")
	exit()
