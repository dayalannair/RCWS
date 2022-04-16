import uRAD_USB_SDK11		# uRAD v1.2 USB lib
import uRAD_RP_SDK10		# uRAD v1.1 RPi lib
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
Mth = 4						# MTI threshold. Sets sensitivity with 4 being highest. Vary: find optimal for scenario
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

#Switch on Pi uRAD
uRAD_RP_SDK10.turnON()

# results output array for uRAD Pi
distance_pi = [0] * Ntar
SNR_pi = [0] * Ntar
velocity_pi = [0] * Ntar

# load config for uRAD USB
return_code_usb = uRAD_USB_SDK11.loadConfiguration(ser, mode, f0, BW, Ns, Ntar, Rmax, MTI, Mth, Alpha, distance_true, velocity_true, SNR_true, I_true, Q_true, movement_true)

# no return code from SDK 1.0 for RPi
uRAD_RP_SDK10.loadConfiguration(mode, f0, BW, Ns, Ntar, Rmax, MTI, Mth)

if return_code_usb != 0:
	closeProgram()
	print("Could not load config uRAD USB")

if (not usb_communication):
	sleep(timeSleep)

# infinite detection loop
print("Beginning loop")
resultsUSBFileName = 'uRAD_USB_results.txt'
fileResultsUSB = open(resultsUSBFileName, 'a')

resultsPiFileName = 'uRAD_Pi_results.txt'
fileResultsPi = open(resultsPiFileName, 'a')

while True:
	try:
		#sleep(0.5)
		# Extract results from uRAD USB running SDK1.1
		return_code_usb, results_usb, raw_results_usb = uRAD_USB_SDK11.detection(ser)
		#print("Serial data recorded")
		# Extract results from Pi uRAD runnning SDK1.0
		uRAD_RP_SDK10.detection(distance_pi, velocity_pi, SNR_pi, 0, 0, 0)
		#print("SPI data recorded")
		#print(SNR_pi)
		if return_code_usb != 0:
			print("USB detection error")
			closeProgram()


		# Extract results from outputs
		NtarDetected_usb = results_usb[0]
		distance_usb = results_usb[1]
		velocity_usb = results_usb[2]
		SNR_usb = results_usb[3]

		# reset turn safety. Processing quick enough to revert this to False if turn is still unsafe
		turn_safe = True

		# USE PTHREAD?

		# Iterate through desired targets
		for i in range(Ntar):
			# If SNR is big enough
			if SNR_usb[i] > 0:
				print("USB Target: %d, Distance: %1.2f m, Velocity: %1.1f m/s, SNR: %1.1f dB" % (i+1, distance_usb[i], velocity_usb[i], SNR_usb[i]))
				fileResultsUSB.write("USB Target: %d, Distance: %1.2f m, Velocity: %1.1f m/s, SNR: %1.1f dB \n" % (i+1, distance_usb[i], velocity_usb[i], SNR_usb[i]))
				# could put calc in if statement 
				if velocity_usb[i] != 0:
					t_arrival = distance_usb[i]/velocity_usb[i]
					# this needs to be nested as velocity of 0 will keep t_arrival < t_accel
					if (t_arrival < t_accel):
						# turn unsafe if one target will arrive too soon
						print("Turn unsafe USB. Arrival time: %1.3f seconds" % t_arrival)
						turn_safe = False
			
			if SNR_pi[i] > 0:
				print("Pi Target: %d, Distance: %1.2f m, Velocity: %1.1f m/s, SNR: %1.1f dB" % (i+1, distance_pi[i], velocity_pi[i], SNR_pi[i]))
				fileResultsPi.write("Pi Target: %d, Distance: %1.2f m, Velocity: %1.1f m/s, SNR: %1.1f dB \n" % (i+1, distance_pi[i], velocity_pi[i], SNR_pi[i]))
				if velocity_pi[i] != 0:
					t_arrival = distance_pi[i]/velocity_pi[i]
					# this needs to be nested as velocity of 0 will keep t_arrival < t_accel
					if (t_arrival < t_accel):
						# turn unsafe if one target will arrive too soon
						print("Turn unsafe Pi. Arrival time: %1.3f seconds" % t_arrival)
						turn_safe = False
				print(" ")


	# This program runs on each node/ uRAD sensor.
	# Need overarching comms program to determine if turn safe on both sides

		# If number of detected targets is greater than 0 prints an empty line for a smarter output
		if (NtarDetected_usb > 0):
			print(" ")

		# Sleep during specified time
		if (not usb_communication):
			sleep(timeSleep)

	except KeyboardInterrupt:
		print("Exiting gracefully\n")
		uRAD_RP_SDK10.turnOFF()
		uRAD_USB_SDK11.turnOFF(ser)
		fileResultsPi.close()
		fileResultsUSB.close()
		exit()

