import uRAD_USB_SDK11
import serial
from time import time, sleep, time_ns
import sys
from datetime import datetime
# True if USB, False if UART
usb_communication = True

try:
	mode_in = str(sys.argv[1])
	BW = int(sys.argv[2])
	Ns = int(sys.argv[3])
	sweeps = int(sys.argv[4])
	fs = 200000
	now = datetime.now()
	expected_period = Ns/200000
	runtime = sweeps*expected_period
	if mode_in == "s":
		print("********** SAWTOOTH MODE **********")
		resultsFileName = 'IQ_saw_' + str(BW) + '_' + str(Ns) +  '_' + str(now) + '.txt'
		mode = 2					
	elif mode_in == "t":
		print("********** TRIANGLE MODE **********")
		resultsFileName = 'IQ_tri_' + str(BW) + '_' + str(Ns) + '_' + str(now) + '.txt'
		mode = 3					
	else: 
		print("Invalid mode")
		exit()
	print("BW = ",str(BW),"\nNs = ",str(Ns),"\nSweeps = ",str(sweeps))
	print("Expected run time: ",str(runtime))
	print("Expected period: ",str(expected_period))
except: 
	print("Invalid mode")
	exit()


# input parameters
f0 = 5						# starting at 24.005 GHz
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

t_0 = time_ns()
t_i = []
i = 0
I = []
Q = []
print("Loop running\n")
print(str(t_0/10e9))
try:
	for i in range(sweeps):
		return_code, results, raw_results = uRAD_USB_SDK11.detection(ser)
		I.append(raw_results[0])
		Q.append(raw_results[1])
		t_i.append(time_ns())

		# Signal period
		period = t_i[len(t_i)-1]-t_i[len(t_i)-2]
		
		# Elapsed time
		# period = t_i[len(t_i)-1] - t_0

		print(str(period/10e9))

	print("Ending. Writing data to textfile...\n")
	uRAD_USB_SDK11.turnOFF(ser)
	sweeps = len(I)
	samples = len(I[1])
	
	with open(resultsFileName, 'w') as f:
		for sweep in range(sweeps):
			IQ_string = ''
			for sample in range(samples):
				IQ_string += '%d ' % I[sweep][sample]
			for sample in range(samples):
				IQ_string += '%d ' % Q[sweep][sample]
			f.write(IQ_string + '%1.3f\n' % int(t_i[sweep]/10e9))
	print("Complete.")
	
except KeyboardInterrupt:
	uRAD_USB_SDK11.turnOFF(ser)
	print("Interrupted.")
	exit()
