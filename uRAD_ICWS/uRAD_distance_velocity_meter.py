import uRAD_USB_SDK11		# import uRAD libray
import serial
from time import time, sleep

# True if USB, False if UART
usb_communication = True

# input parameters
mode = 4					# triangular dual rate mode
f0 = 5						# start frequency 24.005 GHz
BW = 240					# sweep 240 MHz
Ns = 200					# 200 samples
Ntar = 3					# 3 target of interest
Rmax = 100					# searching along the full distance range
MTI = 0						# MTI mode disable because we want information of static and moving targets
Mth = 0						# parameter not used because "movement" is not requested
Alpha = 10					# signal has to be 10 dB higher than its surrounding
distance_true = True 		# request distance information
velocity_true = True		# request velocity information
SNR_true = True 			# Signal-to-Noise-Ratio information requested
I_true = False 				# In-Phase Component (RAW data) not requested
Q_true = False 				# Quadrature Component (RAW data) not requested
movement_true = False 		# not interested in boolean movement detection
print("Running")
# Serial Port configuration
ser = serial.Serial()
if (usb_communication):
	ser.port = '/dev/ttyACM0'#'/dev/ttyS3' # for WSL
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

# Method to correctly turn OFF and close uRAD
def closeProgram():
	# switch OFF uRAD
	return_code = uRAD_USB_SDK11.turnOFF(ser)
	if (return_code != 0):
		exit()

# Open serial port
try:
	ser.open()
except:
	print("Could not open serial conn \n")
	closeProgram()

# switch ON uRAD
return_code = uRAD_USB_SDK11.turnON(ser)
if (return_code != 0):
	print("Could not turn on uRAD \n")
	closeProgram()

if (not usb_communication):
	sleep(timeSleep)

# loadConfiguration uRAD
return_code = uRAD_USB_SDK11.loadConfiguration(ser, mode, f0, BW, Ns, Ntar, Rmax, MTI, Mth, Alpha, distance_true, velocity_true, SNR_true, I_true, Q_true, movement_true)
if (return_code != 0):
	print("Could not load configuration \n")
	closeProgram()

if (not usb_communication):
	sleep(timeSleep)

# infinite detection loop
while True:

	# target detection request
	return_code, results, raw_results = uRAD_USB_SDK11.detection(ser)
	if (return_code != 0):
		print("Detection error \n")
		closeProgram()

	# Extract results from outputs
	NtarDetected = results[0]
	distance = results[1]
	velocity = results[2]
	SNR = results[3]

	# Iterate through desired targets
	for i in range(NtarDetected):
		# If SNR is big enough
		if (SNR[i] > 0):
			# Prints target information
			print("Target: %d, Distance: %1.2f m, Velocity: %1.1f m/s, SNR: %1.1f dB" % (i+1, distance[i], velocity[i], SNR[i]))

	# If number of detected targets is greater than 0 prints an empty line for a smarter output
	if (NtarDetected > 0):
		print(" ")

	# Sleep during specified time
	if (not usb_communication):
		sleep(timeSleep)
