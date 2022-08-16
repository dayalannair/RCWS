import sys
sys.path.append('../python_modules')
import uRAD_RP_SDK10		# uRAD v1.1 RPi lib
from time import time, sleep, strftime,localtime
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


#Switch on Pi uRAD
uRAD_RP_SDK10.turnON()
# no return code from SDK 1.0 for RPi
uRAD_RP_SDK10.loadConfiguration(mode, f0, BW, Ns, 0, 0, 0, 0)

# 2* because 200 up and 200 down for each
Q_temp = [0] * 2 * Ns
I_temp = [0] * 2 * Ns

I_rpi = []
Q_rpi = []

t_0 = time()

print("System running...")

PifileName = "IQ_pi.txt"
USBfileName = "IQ_usb.txt"
try:
	for i in range(sweeps):
		# fetch IQ from uRAD Pi
		uRAD_RP_SDK10.detection(0, 0, 0, I_temp, Q_temp, 0)
		# fetch IQ from uRAD USB

		I_rpi.append(I_temp[:])
		Q_rpi.append(Q_temp[:])

	print("Elapsed time: ", str(time()-t_0))
	print("Saving data...")
	with open(PifileName, 'w') as rpi:
		for sweep in range(sweeps):
			IQ_rpi = ''
			IQ_usb = ''
			# Length is 2*Ns
			up_down_length = len(I_rpi[0])
			# Store I data
			for sample in range(up_down_length):
				IQ_rpi += '%d ' % I_rpi[sweep][sample]
			# Store Q data
			for sample in range(up_down_length):
				IQ_rpi += '%d ' % Q_rpi[sweep][sample]
			#f.write(IQ_string + '%1.3f\n' % t_i[sweep])
			rpi.write(IQ_rpi + '\n')

	uRAD_RP_SDK10.turnOFF()
	print("Complete.")
	
except KeyboardInterrupt:
	uRAD_RP_SDK10.turnOFF()
	print("Interrupted.")
	exit()
