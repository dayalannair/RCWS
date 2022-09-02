import sys
sys.path.append('../../custom_modules')

import uRAD_USB_SDK11
import uRAD_RP_SDK10		# uRAD v1.1 RPi lib
import serial
from time import time, sleep, strftime,localtime
import sys
from pyDSPv2 import py_trig_dsp
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
c = 299792458
rng_ax = c*fax/(2*slope)
return_code, results, raw_results = uRAD_USB_SDK11.detection(ser)
if (return_code != 0):
	closeProgram()
		# I.append(raw_results[0])
		# Q.append(raw_results[1])
		# call matlab dsp
I = raw_results[0]
Q = raw_results[1]
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
f_ax = np.linspace(0, round(fs/2), round(n_fft/2))
os_pku, os_pkd, upth, dnth, fftu, fftd, safety_inv, beat_index, beat_min, rg_array, \
	sp_array = py_trig_dsp(I,Q, twin, n_fft, num_nul, half_train, half_guard, rank, nbins, bin_width, f_ax)
plt.ion()
print(beat_index)
print(beat_min)
plt.show(block=False)

# Ignore divide by zero
# numpy.seterr(divide = 'ignore')

# ===== LOG SCALE ==============
# upth = 20*np.log10(upth)
# dnth = 20*np.log10(dnth)
# fftu = 20*np.log10(abs(fftu))
# fftd = 20*np.log10(abs(fftd))
# os_pku = 20*np.log10(abs(os_pku))
# os_pkd = 20*np.log10(abs(os_pkd))

fig1, ax = plt.subplots(nrows=4, ncols=1, figsize=(5, 6)) #, constrained_layout=True)
ax[0].set_xlim([0, 62.5])
ax[0].set_ylim([90, 180])
ax[1].set_xlim([0, 62.5])
ax[1].set_ylim([90, 180])
ax[2].set_xlim([0, 62.5])
ax[2].set_ylim([90, 180])
ax[3].set_xlim([0, 62.5])
ax[3].set_ylim([90, 180])

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
line1_pi, = ax[2].plot(rng_ax, fftu)
line2_pi, = ax[2].plot(rng_ax, upth)
line3_pi, = ax[3].plot(rng_ax, fftd)
line4_pi, = ax[3].plot(rng_ax, dnth)

ax[0].set_title("USB Down chirp spectrum negative half flipped")
ax[1].set_title("USB Up chirp spectrum positive half")

ax[0].set_xlabel("Coupled Range (m)")
ax[1].set_xlabel("Coupled Range (m)")

ax[0].set_ylabel("Magnitude (dB)")
ax[1].set_ylabel("Magnitude (dB)")

ax[2].set_title("RPI Down chirp spectrum negative half flipped")
ax[3].set_title("RPI Up chirp spectrum positive half")

ax[2].set_xlabel("Coupled Range (m)")
ax[3].set_xlabel("Coupled Range (m)")

ax[2].set_ylabel("Magnitude (dB)")
ax[3].set_ylabel("Magnitude (dB)")


print("System running...")
# safety_inv = np.zeros(sweeps)
# safety_inv_pi = np.zeros(sweeps)
plt.pause(0.1)
bg1 = fig1.canvas.copy_from_bbox(fig1.bbox)

fig1.canvas.blit(fig1.bbox)
# ======================= CAMERAS ================================
cap1 = cv2.VideoCapture(0)
cap2 = cv2.VideoCapture(2)

# cap1.set(3, 320)
# cap1.set(4, 240)

# cap2.set(3, 320)
# cap2.set(4, 240)

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
		ret1,frame1 = cap1.read()
		ret2,frame2 = cap2.read()
		cv2.imshow(win1,cv2.flip(frame1,0))
		# cv2.imshow(win1,frame1)
		cv2.imshow(win2,frame2)
		cv2.waitKey(1)
		t1 = time() - t0
	cap1.release()	
	cap2.release()

vid1 = threading.Thread(target=capture, args=[duration, cap1, cap2])

def dsp_thread_usb():
	global n_fft
	global twin
	global num_nul
	global half_guard
	global half_train
	global f_ax
	global bin_width
	global nbins
	global rank
	global upth
	global dnth
	global fftd
	global fftu
	global I
	global Q
	return_code, results, raw_results = uRAD_USB_SDK11.detection(ser)
	if (return_code != 0):
		closeProgram()
	os_pku, os_pkd, upth, dnth, fftu, fftd, safety_inv, beat_index, beat_min,\
	rg_array, sp_array = py_trig_dsp(raw_results[0],raw_results[1], twin, n_fft, num_nul, half_train, \
	half_guard, rank, nbins, bin_width, f_ax)

def dsp_thread_rpi():
	global n_fft
	global twin
	global num_nul
	global half_guard
	global half_train
	global f_ax
	global bin_width
	global nbins
	global rank
	global upth_pi
	global dnth_pi
	global fftd_pi
	global fftu_pi
	global I_pi
	global Q_pi
	uRAD_RP_SDK10.detection(0, 0, 0, I_pi, Q_pi, 0)
	os_pku, os_pkd, upth_pi, dnth_pi, fftu_pi, fftd_pi, safety_inv, beat_index, beat_min,\
	rg_array, sp_array = py_trig_dsp(I_pi,Q_pi, twin, n_fft, num_nul, half_train, \
	half_guard, rank, nbins, bin_width, f_ax)

proc_usb = threading.Thread(target=dsp_thread_usb, args=[])
proc_rpi = threading.Thread(target=dsp_thread_rpi, args=[])
try:
	vid1.start()
	t0 = time()
	t1 = 0

	while (t1<duration):

		# I = raw_results[0]
		# Q = raw_results[1]
		proc_usb = threading.Thread(target=dsp_thread_usb, args=[])
		proc_rpi = threading.Thread(target=dsp_thread_rpi, args=[])
		t0_proc = time()
		proc_usb.start()
		proc_rpi.start()
		proc_usb.join()
		proc_rpi.join()
		# os_pku, os_pkd, upth, dnth, fftu, fftd, safety_inv, beat_index, beat_min, rg_array, sp_array = py_trig_dsp(I,Q, twin, n_fft, num_nul, half_train, half_guard, rank, nbins, bin_width, f_ax)
		# os_pku_pi, os_pkd_pi, upth_pi, dnth_pi, fftu_pi, fftd_pi, safety_inv_pi, beat_index_pi, beat_min_pi, rg_array_pi, sp_array_pi = py_trig_dsp(I_pi,Q_pi, twin, n_fft, num_nul, half_train, half_guard, rank, nbins, bin_width, f_ax)
		
		
		# np.concatenate((rg_full, rg_array))
		# rg_full[i*16:(i+1)*16] = rg_array
		# print(safety_inv[i])
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

		line1_pi.set_ydata(20*np.log10(abs(fftu_pi)))
		line2_pi.set_ydata(20*np.log10(upth_pi))
		line3_pi.set_ydata(20*np.log10(abs(fftd_pi)))
		line4_pi.set_ydata(20*np.log10(dnth_pi))
		# =============================================

		# NEED LOG SCALE
		# line1.set_ydata(fftu)
		# line2.set_ydata(upth)
		# line3.set_ydata(fftd)
		# line4.set_ydata(dnth)
		# line1_pi.set_ydata(fftu_pi)
		# line2_pi.set_ydata(upth_pi)
		# line3_pi.set_ydata(fftd_pi)
		# line4_pi.set_ydata(dnth_pi)

		# line9 = ax[1].axvline(rng_ax[beat_index])
		# line10 = ax[1].axvline(rng_ax[beat_min])
		# line9.remove()
		# line10.remove()
		
		ax[0].draw_artist(line1)
		ax[0].draw_artist(line2)
		ax[1].draw_artist(line3)
		ax[1].draw_artist(line4)

		ax[2].draw_artist(line1_pi)
		ax[2].draw_artist(line2_pi)
		ax[3].draw_artist(line3_pi)
		ax[3].draw_artist(line4_pi)
		fig1.canvas.blit(fig1.bbox)
		fig1.canvas.flush_events()
		t1 = time() - t0
		
	vid1.join()
	# vid2.join()
	print("Elapsed time: ", str(time()-t_0))

	print("Complete.")
	cap1.release()
	cap2.release()
	uRAD_RP_SDK10.turnOFF()
	uRAD_USB_SDK11.turnOFF(ser)
	
except KeyboardInterrupt:
	cap1.release()
	cap2.release()
	uRAD_RP_SDK10.turnOFF()
	uRAD_USB_SDK11.turnOFF(ser)
	print("Interrupted.")
	exit()
