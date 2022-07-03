import uRAD_USB_SDK11		# import uRAD libray
import serial
from time import time, sleep

# True if USB, False if UART
usb_communication = True

# input parameters
mode = 3					# triangle mode
f0 = 5						# starting at 24.005 GHz
BW = 240					# using all the BW available = 240 MHz
Ns = 200					# 200 samples
Ntar = 1					# Don't apply as only raw data is desired
Rmax = 62					# Don't apply as only raw data is desired
MTI = 2						# MTI mode disable because we want information of static and moving targets
Mth = 1						# Don't apply as only raw data is desired
Alpha = 10					# Don't apply to raw signals
distance_true = False 		# Don't request distance information
velocity_true = False		# Don't request velocity information
SNR_true = False 			# Don't request Signal-to-Noise-Ratio information
I_true = True 				# In-Phase Component (RAW data) requested
Q_true = True 				# Quadrature Component (RAW data) requested
movement_true = False 		# Don't apply as only raw data is desired

# Serial Port configuration
ser = serial.Serial()
if (usb_communication):
	ser.port = 'COM3'
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
		exit()

# Open serial port
try:
	ser.open()
except:
	closeProgram()

# switch ON uRAD
return_code = uRAD_USB_SDK11.turnON(ser)
if (return_code != 0):
	closeProgram()

if (not usb_communication):
	sleep(timeSleep)

# loadConfiguration uRAD
return_code = uRAD_USB_SDK11.loadConfiguration(ser, mode, f0, BW, Ns, Ntar, Rmax, MTI, Mth, Alpha, distance_true, velocity_true, SNR_true, I_true, Q_true, movement_true)
if (return_code != 0):
	closeProgram()

if (not usb_communication):
	sleep(timeSleep)

resultsFileName = 'IQ.txt'
#fileResults = open(resultsFileName, 'w')
# iterations = 0
t_0 = time()
i = 0
I = []
Q = []
t_i = []
# infinite detection loop
print("Loop running\n")
while True:
	try:
		# target detection request
		return_code, results, raw_results = uRAD_USB_SDK11.detection(ser)
		# Extract results from outputs
		I.append(raw_results[0])
		Q.append(raw_results[1])
		t_i.append(time())
		period = t_i[len(t_i)-1]-t_i[len(t_i)-2]
		print(str(period))

		# i = i + 1
		# if i>100:
		# 	fupdate = i/(t_i[len(t_i)-1]-t_0)
		# 	period = t_i[len(t_i)-1]-t_i[len(t_i)-2]
		# 	print(str(fupdate))
		# 	print(str(period))
		# I

	except KeyboardInterrupt:
		print("Ending. Writing data to textfile\n")
		I
		uRAD_USB_SDK11.turnOFF(ser)

		with open(resultsFileName, 'w') as f:
			for j in range(len(I)):
				IQ_string = ''
				for index in range(len(I)):
					IQ_string += '%d ' % I[j][index]
				for index in range(len(Q)):
					IQ_string += '%d ' % Q[j][index]
				f.write(IQ_string + '%1.3f\n' % t_i[j])
		exit()
