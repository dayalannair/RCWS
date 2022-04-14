import uRAD_USB_SDK11		# uRAD v1.2 USB lib
import serial
from time import time, sleep

# True if USB, False if UART
usb_communication = True

# input parameters
mode = 3					# triangular. Try dual rate mode as well
f0 = 5						# start frequency 24.005 GHz
BW = 240					# sweep 240 MHz
Ns = 200					# 200 samples
Ntar = 2					# 2 target of interest
Rmax = 100					# searching along the full distance range
MTI = 1						# MTI mode enabled: only want information on moving targets
Mth = 2						# MTI threshold. Sets sensitivity with 4 being highest. Vary: find optimal for scenario
Alpha = 10					# signal has to be 10 dB higher than its surrounding. may need tuning
distance_true = True 		# request distance information
velocity_true = True		# request velocity information
SNR_true = True 			# Signal-to-Noise-Ratio information requested
I_true = False 				# In-Phase Component (RAW data) not requested
Q_true = False 				# Quadrature Component (RAW data) not requested
movement_true = False 		# not interested in boolean movement detection

# ICWS parameters
t_accel = 5					# time taken for host to match speed. Depends on car, chosen realistically (slow/normal turn)
t_arrival = 0				# time at which target vehicle is directly in front of host
turn_safe = True			# Indicates turn safety based on D and V of all targets detected
#safeDistance

# Serial Port configuration
ser = serial.Serial()
if (usb_communication):
	# Port differs for different PCs
	ser.port = '/dev/ttyACM0'
	ser.baudrate = 1e6
else:
	# UART
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
	print("Exiting gracefully\n")
	# switch OFF uRAD
	return_code_usb = uRAD_USB_SDK11.turnOFF(ser)
	if (return_code_usb != 0):
		exit()

# Open serial port
try:
	ser.open()
except:
	print("Could not open serial")
	closeProgram()
	

# switch ON uRAD
return_code_usb = uRAD_USB_SDK11.turnON(ser)
if (return_code_usb != 0):
	closeProgram()
	print("Could not turn on USB uRAD")

if (not usb_communication):
	sleep(timeSleep)

# load config for uRAD USB
return_code_usb = uRAD_USB_SDK11.loadConfiguration(ser, mode, f0, BW, Ns, Ntar, Rmax, MTI, Mth, Alpha, distance_true, velocity_true, SNR_true, I_true, Q_true, movement_true)

if return_code_usb != 0:
	closeProgram()
	print("Could not load config uRAD USB")

if (not usb_communication):
	sleep(timeSleep)

# infinite detection loop
print("Beginning loop")
resultsUSBFileName = 'uRAD_USB_results.txt'
fileResultsUSB = open(resultsUSBFileName, 'w')
t  = time()
while True:
	try:
		return_code_usb, results_usb, raw_results_usb = uRAD_USB_SDK11.detection(ser)
		if return_code_usb != 0:
			print("USB detection error")
			closeProgram()

		NtarDetected_usb = results_usb[0]
		distance_usb = results_usb[1]
		velocity_usb = results_usb[2]
		SNR_usb = results_usb[3]
		t = time()

		# reset turn safety. Processing quick enough to revert this to False if turn is still unsafe
		turn_safe = True
		# Iterate through desired targets
		for i in range(Ntar):
			# If SNR is big enough
			if SNR_usb[i] > 0:
				#print("USB Target: %d, Distance: %1.2f m, Velocity: %1.1f m/s, SNR: %1.1f dB" % (i+1, distance_usb[i], velocity_usb[i], SNR_usb[i]))
				# could put calc in if statement 
				if velocity_usb[i] != 0:
					t_arrival = distance_usb[i]/velocity_usb[i]
					# this needs to be nested as velocity of 0 will keep t_arrival < t_accel
					if (t_arrival < t_accel):
						turn_safe=False
						fileResultsUSB.write("%d %1.2f %1.1f %1.1f %1.3f %s\n" % (i+1, distance_usb[i], velocity_usb[i], SNR_usb[i], t, "F"))
					else:
						fileResultsUSB.write("%d %1.2f %1.1f %1.1f %1.3f %s\n" % (i+1, distance_usb[i], velocity_usb[i], SNR_usb[i], t, "T"))

				else:		
					fileResultsUSB.write("%d %1.2f %1.1f %1.1f %1.3f %s\n" % (i+1, distance_usb[i], velocity_usb[i], SNR_usb[i], t, "T"))



		# Sleep during specified time
		if (not usb_communication):
			sleep(timeSleep)

	except KeyboardInterrupt:
		print("Exiting gracefully\n")
		uRAD_USB_SDK11.turnOFF(ser)
		fileResultsUSB.close()
		exit()

