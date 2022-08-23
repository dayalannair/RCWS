import sys
sys.path.append('../python_modules')
import uRAD_USB_SDK11
import uRAD_RP_SDK10		# uRAD v1.1 RPi lib
import serial
from time import time, sleep, strftime,localtime
import threading
import matplotlib.pyplot as plt
import numpy as np
from pyDSPv2 import py_trig_dsp
from pyqtgraph.Qt import QtGui, QtCore
import pyqtgraph as pg

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
app = QtGui.QApplication([])

# plt.ion()
xmin = 0
xmax = 256
ymin = 50
ymax = 160
print("System running...")
# ================================================================
# 							uRAD threads
# ================================================================
def rpi_urad_capture(duration):
	print("uRAD RPI thread running...")

	# fig1, ax = plt.subplots(nrows=2, ncols=1, figsize=(10, 8))
	# tmp = np.zeros(256)
	# line1, = ax[0].plot(tmp, animated=True)
	# line2, = ax[1].plot(tmp, animated=True)
	# plt.show(block=False)
	# ax[0].set_title("USB Down chirp spectrum negative half flipped")
	# ax[0].set_xlabel("Coupled Range (m)")
	# ax[0].set_ylabel("Magnitude (dB)")

	# ax[1].set_title("USB Up chirp spectrum positive half")
	# ax[1].set_xlabel("Coupled Range (m)")
	# ax[1].set_ylabel("Magnitude (dB)")
	
	# ax[0].set(xlim=(xmin, xmax), ylim=(ymin, ymax))
	# ax[1].set(xlim=(xmin, xmax), ylim=(ymin, ymax))
	# plt.pause(0.1)
	# bg1 = fig1.canvas.copy_from_bbox(fig1.bbox)

	# ax[0].draw_artist(line1)
	# ax[1].draw_artist(line2)

	# fig1.canvas.blit(fig1.bbox)


	# ax0background = fig1.canvas.copy_from_bbox(ax[0].bbox)
	# ax1background = fig1.canvas.copy_from_bbox(ax[1].bbox)

	p = pg.plot()
	p.setWindowTitle('live plot from serial')	
	curve = p.plot()
	


	Q_temp = [0] * 2 * Ns
	I_temp = [0] * 2 * Ns
	# line1, = ax[0].plot()
	# line2, = ax[1].plot()
	t0 = time()
	t1 = 0

	# Capture data
	while (t1 < duration):
		uRAD_RP_SDK10.detection(0, 0, 0, I_temp, Q_temp, 0)

		
		os_pku, os_pkd, upth, dnth, fftu, fftd, safety_inv, beat_index, beat_min, rg_array, sp_array = py_trig_dsp(I_temp,Q_temp)

		curve.setData(20*np.log10(fftu))

		# fig1.canvas.restore_region(bg1)
		# line1.set_ydata(20*np.log10(fftu))
		# line2.set_ydata(20*np.log10(fftd))
		# ax[0].draw_artist(line1)
		# ax[1].draw_artist(line2)
		# fig1.canvas.blit(fig1.bbox)
		# fig1.savefig('thread_out1.jpeg')
		# fig1.canvas.flush_events()
		t1 = time() - t0
		# fig1.canvas.flush_events()



def usb_urad_capture(duration):
	print("uRAD USB thread running...")
	t0 = time()
	t1 = 0

	fig2, ax = plt.subplots(nrows=2, ncols=1, figsize=(10, 8))
	tmp = np.zeros(256)
	line1, = ax[0].plot(tmp, animated=True)
	line2, = ax[1].plot(tmp, animated=True)
	plt.show(block=False)
	ax[0].set_title("USB Down chirp spectrum negative half flipped")
	ax[0].set_xlabel("Coupled Range (m)")
	ax[0].set_ylabel("Magnitude (dB)")

	ax[1].set_title("USB Up chirp spectrum positive half")
	ax[1].set_xlabel("Coupled Range (m)")
	ax[1].set_ylabel("Magnitude (dB)")

	ax[0].set(xlim=(xmin, xmax), ylim=(ymin, ymax))
	ax[1].set(xlim=(xmin, xmax), ylim=(ymin, ymax))

	plt.pause(0.1)
	bg2 = fig2.canvas.copy_from_bbox(fig2.bbox)

	ax[0].draw_artist(line1)
	ax[1].draw_artist(line2)

	fig2.canvas.blit(fig2.bbox)


	# Capture data
	while (t1 < duration):
		return_code, results, raw_results = uRAD_USB_SDK11.detection(ser)
		if (return_code != 0):
			closeProgram()
		os_pku, os_pkd, upth, dnth, fftu, fftd, safety_inv, beat_index, beat_min, rg_array, sp_array = py_trig_dsp(raw_results[0],raw_results[1])
		fig2.canvas.restore_region(bg2)
		line1.set_ydata(20*np.log10(fftu))
		line2.set_ydata(20*np.log10(fftd))
		ax[0].draw_artist(line1)
		ax[1].draw_artist(line2)
		fig2.canvas.blit(fig2.bbox)
		fig2.savefig('thread_out2.jpeg')
		fig2.canvas.flush_events()
		t1 = time() - t0

# uRAD threads
rpi_urad = threading.Thread(target=rpi_urad_capture, args=[duration])
usb_urad = threading.Thread(target=usb_urad_capture, args=[duration])

try:
	t_0 = time()
	# Start camera threads
	rpi_urad.start()
	usb_urad.start()
	rpi_urad.join()
	usb_urad.join()
	# print(I_usb)
	print("Elapsed time: ", str(time()-t_0))
	uRAD_RP_SDK10.turnOFF()
	uRAD_USB_SDK11.turnOFF(ser)
	print("Complete.")
	
except KeyboardInterrupt:
	uRAD_RP_SDK10.turnOFF()
	uRAD_USB_SDK11.turnOFF(ser)
	print("Interrupted.")
	exit()
