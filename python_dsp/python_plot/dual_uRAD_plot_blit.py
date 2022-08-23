import uRAD_USB_SDK11
import uRAD_RP_SDK10		# uRAD v1.1 RPi lib
import serial
from time import time, sleep, strftime,localtime
import sys
from pyDSPv2 import py_trig_dsp
from datetime import datetime
import numpy as np
import matplotlib
matplotlib.use('TkAgg')
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
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
plt.show(block=False)
upth = 20*np.log(upth)
dnth = 20*np.log(dnth)
fftu = 20*np.log(abs(fftu))
fftd = 20*np.log(abs(fftd))
os_pku = 20*np.log(abs(os_pku))
os_pkd = 20*np.log(abs(os_pkd))


# x = np.zeros(100, 100)
# y = np.zeros(100, 100)
fig1, ax = plt.subplots(nrows=4, ncols=1, figsize=(10, 8))
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



# CFAR stems
# line5, = ax[0].stem([],cfar_res_up)
# line6, = ax[1].stem([],cfar_res_dn)
# line5, = ax[0].plot(rng_ax, os_pku, markersize=20)
# line6, = ax[1].plot(rng_ax, os_pkd, markersize=20)

# line7, = ax[2].plot(rg_full)
# line8, = ax[3].plot(sp_array)

# ax[1].axvline(rng_ax[beat_index])
# ax[1].axvline(rng_ax[beat_min])
# print(cfar_res_dn)
# eng.eval("load(\'urad_trig_proc_config.mat\')")
print("System running...")
safety_inv = np.zeros(sweeps)
safety_inv_pi = np.zeros(sweeps)

plt.pause(0.1)
bg1 = fig1.canvas.copy_from_bbox(fig1.bbox)

ax[0].draw_artist(line1)
ax[0].draw_artist(line2)
ax[1].draw_artist(line3)
ax[1].draw_artist(line4)

ax[2].draw_artist(line1_pi)
ax[2].draw_artist(line2_pi)
ax[3].draw_artist(line3_pi)
ax[3].draw_artist(line4_pi)

fig1.canvas.blit(fig1.bbox)

try:
	for i in range(sweeps):
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

		fig1.canvas.restore_region(bg1)
		# print(len(cfar_res_up))
		line1.set_ydata(fftu)
		line2.set_ydata(upth)
		line3.set_ydata(fftd)
		line4.set_ydata(dnth)
		# line5.set_ydata(os_pku)
		# line6.set_ydata(os_pkd)

		line1_pi.set_ydata(fftu_pi)
		line2_pi.set_ydata(upth_pi)
		line3_pi.set_ydata(fftd_pi)
		line4_pi.set_ydata(dnth_pi)

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
		

	print("Elapsed time: ", str(time()-t_0))

	print("Complete.")
	
except KeyboardInterrupt:
	uRAD_RP_SDK10.turnOFF()
	uRAD_USB_SDK11.turnOFF(ser)
	print("Interrupted.")
	exit()
