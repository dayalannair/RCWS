import uRAD_USB_SDK11
import serial
from time import time, sleep, time_ns
import sys

# True if USB, False if UART
usb_communication = True

try:
    mode_in = str(sys.argv[1])
    if mode_in == "s":
        print("********** SAWTOOTH MODE **********")
        resultsFileName = 'IQ_sawtooth.txt'
        mode = 2					
    elif mode_in == "t":
        print("********** TRIANGLE MODE **********")
        resultsFileName = 'IQ_triangle.txt'
        mode = 3					
    else: 
        print("Invalid mode")
        exit()
except: 
    print("Invalid mode")
    exit()
# input parameters
f0 = 5						# starting at 24.005 GHz
BW = 240					# using all the BW available = 240 MHz
Ns = 200					# 200 samples
I_true = True 				# In-Phase Component (RAW data) requested
Q_true = True 				# Quadrature Component (RAW data) requested

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
	# switch OFF uRAD
	return_code = uRAD_USB_SDK11.turnOFF(ser)
	if (return_code != 0):
		print("Ending")
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
return_code = uRAD_USB_SDK11.loadConfiguration(ser, mode, f0, BW, Ns, Ntar, Rmax, MTI, Mth, Alpha, distance_true, velocity_true, SNR_true, I_true, Q_true, movement_true)
if (return_code != 0):
	print("uRAD configuration failed")
	closeProgram()

if (not usb_communication):
	sleep(timeSleep)

#fileResults = open(resultsFileName, 'w')
# iterations = 0
t_0 = time_ns()
i = 0
I = []
Q = []
t_i = []
sweeps = 1024
# infinite detection loop
print("Loop running\n")

try:
	for i in range(sweeps):
		return_code, results, raw_results = uRAD_USB_SDK11.detection(ser)
		#print(return_code)
		I.append(raw_results[0])
		Q.append(raw_results[1])
		#t_i.append(clock())
		t_i.append(time_ns())
		
		# Signal period
		#period = t_i[len(t_i)-1]-t_i[len(t_i)-2]
		
		# Elapsed time
		#period = t_i[len(t_i)-1] - t_0
		#print(str(period/10e9))

	# Elapsed time
	period = t_i[len(t_i)-1] - t_0
	print(str(period/10e9))

	uRAD_USB_SDK11.turnOFF(ser)
	print("Ending. Writing data to textfile...\n")
	sweeps = len(I)
	samples = len(I[1])
	
	with open(resultsFileName, 'w') as f:
		for sweep in range(sweeps):
			IQ_string = ''
			for sample in range(samples):
				IQ_string += '%d ' % I[sweep][sample]
			for sample in range(samples):
				IQ_string += '%d ' % Q[sweep][sample]
			#f.write(IQ_string + '%1.3f\n' % t_i[sweep])
			f.write(IQ_string +'\n')
	print("Complete.")
	
except KeyboardInterrupt:
	uRAD_USB_SDK11.turnOFF(ser)
	print("Interrupted.")
	exit()
