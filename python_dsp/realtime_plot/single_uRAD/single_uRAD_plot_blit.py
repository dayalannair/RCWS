import sys
sys.path.append('../../custom_modules')

import uRAD_USB_SDK11
import serial
from time import time, sleep, strftime,localtime
import sys
# from pyDSPv2 import py_trig_dsp
from pyDSP_2pulse import dsp_2pulse
import numpy as np
import matplotlib as mpl
mpl.rcParams['path.simplify'] = True
mpl.rcParams['path.simplify_threshold'] = 1.0
mpl.rcParams['toolbar'] = 'None' 
import matplotlib.style as mplstyle
mplstyle.use(['dark_background', 'ggplot', 'fast'])

import matplotlib.pyplot as plt
import cv2
from matplotlib.gridspec import GridSpec
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

t_0 = time()
i = 0
I1 = []
Q1 = []

I2 = []
Q2 = []

# ------------------------ Frequency axis -----------------
nfft = 512
# kHz Axis
f_ax = np.linspace(0, round(fs/2), round(nfft/2))
# c*fb/(2*slope)
tsweep = 1e-3
bw = 240e6
slope = bw/tsweep
c = 299792458
rng_ax = c*f_ax/(2*slope)
return_code, results, raw_results = uRAD_USB_SDK11.detection(ser)
if (return_code != 0):
	closeProgram()
		# I.append(raw_results[0])
		# Q.append(raw_results[1])
		# call matlab dsp
I1 = raw_results[0]
Q1 = raw_results[1]

return_code, results, raw_results = uRAD_USB_SDK11.detection(ser)
if (return_code != 0):
	closeProgram()
		# I.append(raw_results[0])
		# Q.append(raw_results[1])
		# call matlab dsp
I2 = raw_results[0]
Q2 = raw_results[1]

# rg_full = np.zeros(16*sweeps)
n_fft = 512
twin = signal.windows.taylor(200, nbar=3, sll=100, norm=False)
nul_width_factor = 0.04
num_nul = round((n_fft/2)*nul_width_factor)
# OS CFAR
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
os_pku, os_pkd, upth, dnth, fftu, fftd, safety_inv, beat_index, beat_min, rg_array, \
	sp_array = dsp_2pulse(I1, Q1, I2, Q2, twin, n_fft, num_nul, half_train, \
		half_guard, rank, nbins, bin_width, f_ax)
plt.ion()
print(beat_index)
print(beat_min)
plt.show(block=False)

# ===========================================
# Ignore divide by zero
# =============================================
np.seterr(divide = 'ignore')


fig1, ax = plt.subplots(nrows=2, ncols=1, figsize=(5, 6)) #, constrained_layout=True)
ax[0].set_xlim([0, 62.5])
ax[0].set_ylim([90, 180])
ax[1].set_xlim([0, 62.5])
ax[1].set_ylim([90, 180])


fig1.tight_layout()
# set the spacing between subplots
# plt.subplots_adjust(left=0.1,
#                     bottom=0.1, 
#                     right=0.9, 
#                     top=0.9, 
#                     wspace=0.4, 
#                     hspace=0.4)

line1, = ax[0].plot(rng_ax, fftu)
line2, = ax[0].plot(rng_ax, upth)
line3, = ax[1].plot(rng_ax, fftd)
line4, = ax[1].plot(rng_ax, dnth)

ax[0].set_title("USB Down chirp spectrum negative half flipped")
ax[1].set_title("USB Up chirp spectrum positive half")

ax[0].set_xlabel("Coupled Range (m)")
ax[1].set_xlabel("Coupled Range (m)")

ax[0].set_ylabel("Magnitude (dB)")
ax[1].set_ylabel("Magnitude (dB)")


print("System running...")
# safety_inv = np.zeros(sweeps)
# safety_inv_pi = np.zeros(sweeps)
plt.pause(0.1)
bg1 = fig1.canvas.copy_from_bbox(fig1.bbox)

fig1.canvas.blit(fig1.bbox)

try:
	t0 = time()
	t1 = 0

	while (t1<duration):

		t0_proc = time()

		return_code, results, raw_results = uRAD_USB_SDK11.detection(ser)

		if (return_code != 0):
			closeProgram()

		I1 = raw_results[0]
		Q1 = raw_results[1]

		return_code, results, raw_results = uRAD_USB_SDK11.detection(ser)
		if (return_code != 0):
			closeProgram()

		I2 = raw_results[0]
		Q2 = raw_results[1]
			
		os_pku, os_pkd, upth, dnth, fftu, fftd, safety_inv, beat_index, beat_min, rg_array, \
		sp_array = dsp_2pulse(I1, Q1, I2, Q2, twin, n_fft, num_nul, half_train, \
		half_guard, rank, nbins, bin_width, f_ax)

		for i in range(nbins):
			if rg_array[i]>0:
				print(rg_array[i])
				
		t1_proc = time()-t0_proc

		

		# os_pku = 20*np.log10(abs(os_pku))
		# os_pkd = 20*np.log10(abs(os_pkd))

		fig1.canvas.restore_region(bg1)
		# print(len(cfar_res_up))
		# ============== LOG SCALE =====================
		line1.set_ydata(20*np.log10(abs(fftu)))
		line2.set_ydata(20*np.log10(upth))
		line3.set_ydata(20*np.log10(abs(fftd)))
		line4.set_ydata(20*np.log10(dnth))
		# # line5.set_ydata(os_pku)
		# # line6.set_ydata(os_pkd)
		
		ax[0].draw_artist(line1)
		ax[0].draw_artist(line2)
		ax[1].draw_artist(line3)
		ax[1].draw_artist(line4)

		fig1.canvas.blit(fig1.bbox)
		fig1.canvas.flush_events()
		t1 = time() - t0

	# vid2.join()
	print("Elapsed time: ", str(time()-t_0))

	print("Complete.")
	uRAD_USB_SDK11.turnOFF(ser)
	
except KeyboardInterrupt:
	uRAD_USB_SDK11.turnOFF(ser)
	print("Interrupted.")
	exit()
