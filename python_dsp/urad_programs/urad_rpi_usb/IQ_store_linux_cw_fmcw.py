import uRAD_USB_SDK11
import uRAD_RP_SDK10
import serial
from time import time, sleep, localtime, strftime
import sys
from datetime import datetime

# True if USB, False if UART
usb_communication = True

BW = int(sys.argv[1])
Ns = int(sys.argv[2])
sweeps = int(sys.argv[3])
now = datetime.now()
fs = 200000
runtime = sweeps*Ns/200000
print("******* DUAL CW AND FMCW SAWTOOTH MODE *******")
print("BW = ",str(BW),"\nNs = ",str(Ns),"\nSweeps = ",str(sweeps))
print("Expected run time: ",str(runtime))


# input parameters
# BW and Ns input as arguments
f0_cw = 5						# starting at 24.005 GHz
f0_fm = 100
I_true = True 				# In-Phase Component (RAW data) requested
Q_true = True 				# Quadrature Component (RAW data) requested
mode_fm = 2
mode_cw = 1
# UNUSED FOR RAW DATA OUTPUT
Ntar = 1					# Don't apply as only raw data is desired
Rmax = 62					# Don't apply as only raw data is desired
MTI = 0						# MTI mode disable because we want information of static and moving targets
Mth = 0						# Don't apply as only raw data is desired
Alpha = 0				    # Don't apply to raw signals
distance_true = False 		# Don't request distance information
velocity_true = False		# Don't request velocity information
SNR_true = False 			# Don't request Signal-to-Noise-Ratio information
movement_true = False 		# Don't apply as only raw data is desired

# Serial Port configuration
ser = serial.Serial()
if (usb_communication):
	#ser.port = 'COM3'
	ser.port = '/dev/ttyACM0'
	ser.baudrate = 1e6
else:
	ser.port = '/dev/serial0'
	ser.baudrate = 115200

# Sleep Time (seconds) between iterations
timeSleep = 5e-3

# Other serial parameters
ser.bytesize = serial.EIGHTBITS
ser.parity = serial.PARITY_NONE
ser.stopbits = serial.STOPBITS_ONE
ser.timeout = 1

# Method to correctly turn OFF and close uRAD
def closeProgram():
	print("Exiting gracefully\n")
	# switch OFF uRAD
	return_code = uRAD_USB_SDK11.turnOFF(ser)
	if (return_code != 0):
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
	print("uRAD USB failed to turn on")
	closeProgram()

if (not usb_communication):
	sleep(timeSleep)

# loadConfiguration uRAD
return_code = uRAD_USB_SDK11.loadConfiguration(ser, mode_fm, f0_fm, BW, Ns, 0, 0, 0, 0, 0, 0, 0, 0, I_true, Q_true, 0)
if (return_code != 0):
	print("uRAD USB configuration failed")
	closeProgram()

if (not usb_communication):
	sleep(timeSleep)

uRAD_RP_SDK10.loadConfiguration(mode_cw, f0_cw, 0, 0, 0, 0, 0, 0)

t_0 = time()
i = 0
I_fm = []
Q_fm = []
I_cw = []
Q_cw = []
t = localtime()
current_time = strftime("%H-%M-%S", t)
fcw = "iq_CW_fmcw_" + current_time + ".txt"
ffm = "iq_CW_fmcw_" + current_time + ".txt"
print("Loop running\n")
try:
	for i in range(sweeps):
		return_code, results, raw_results = uRAD_USB_SDK11.detection(ser)
		I.append(raw_results[0])
		Q.append(raw_results[1])

	print("Ending. Writing data to textfile...\n")
	uRAD_USB_SDK11.turnOFF(ser)
	sweeps = len(I_fm)
	samples = len(I_fm[1])
	
	with open(fcw, 'w') as cw, open(ffm, 'w') as fm:
		for sweep in range(sweeps):
			IQ_string = ''
			for sample in range(samples):
				IQ_string += '%d ' % I[sweep][sample]
			for sample in range(samples):
				IQ_string += '%d ' % Q[sweep][sample]
			#f.write(IQ_string + '%1.3f\n' % t_i[sweep])
			cw.write(IQ_string +'\n')

			IQ_string = ''
			for sample in range(samples):
				IQ_string += '%d ' % I[sweep][sample]
			for sample in range(samples):
				IQ_string += '%d ' % Q[sweep][sample]
			fm.write(IQ_string +'\n')
	print("Complete.")
	
except KeyboardInterrupt:
	uRAD_USB_SDK11.turnOFF(ser)
	print("Interrupted.")
	exit()
