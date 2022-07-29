import uRAD_USB_SDK11
import serial
from time import time, sleep, strftime,localtime
import sys
from datetime import datetime
import matlab.engine
import numpy as np
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
	ser.port = 'COM7'
	# ser.port = '/dev/ttyACM0'
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

t_0 = time()
i = 0
I = []
Q = []

print("Initialising MATLAB engine...")
eng = matlab.engine.start_matlab()
print("Configuring system parameters and MATLAB workspace...")
# Radar parameters
c = 3e8
fc = 24.005e9
lda = c/fc
tm = 1e-3
bw = 240e6
sweep_slope = bw/tm
Ns = 200
# Taylor window parameters
nbar = 4
sll = -38
# FFT parameters
nfft = 512
nul_width_factor = 0.04
num_nul = round((nfft/2)*nul_width_factor)
# OS CFAR parameters
guard = 2*nfft/Ns
guard = int(np.floor(guard/2)*2) # make even
train = round(20*nfft/Ns)
train = int(np.floor(train/2)*2)
rank = train
Pfa = 15e-3
# bin method
nbins = 16
bin_width = (nfft/2)/nbins
eng.workspace['lambda'] = lda
eng.workspace['k'] = sweep_slope
eng.workspace['Ns'] = Ns
eng.workspace['c'] = c

# twinu, twind = np.array(eng.proc_twin(nbar, sll, Ns, nargout=2))
# print(np.size(twinu), np.size(twind))
eng.workspace['twinu'], eng.workspace['twind'] = eng.proc_twin(nbar, sll, Ns, nargout=2)
eng.workspace['OS'] = eng.proc_oscfar(train, guard, rank, Pfa)
eng.workspace['f_pos'] = eng.proc_faxis(nfft, nargout=1)

eng.workspace['n_fft'] = nfft
eng.workspace['nbins'] = nbins
eng.workspace['bin_width'] = bin_width
eng.workspace['t_safe'] = 3
eng.workspace['num_nul'] = num_nul
eng.workspace['fd_max'] = 3e3
print("System running...")
try:
	for i in range(sweeps):
		return_code, results, raw_results = uRAD_USB_SDK11.detection(ser)
		if (return_code != 0):
			closeProgram()
		# I.append(raw_results[0])
		# Q.append(raw_results[1])
		# call matlab dsp
		eng.workspace['i_data'] = raw_results[0]
		eng.workspace['q_data'] = raw_results[1]
		t0_proc = time()
		eng.proc_triang_script(nargout=0)
		t1_proc = time()-t0_proc
		print("Processing time: ", t1_proc)
		# if eng.workspace['safety']<10:
		# 	print("Range of hazardous target: ", eng.workspace['targ_rng'])
		# 	print("Speed of hazardous target: ", eng.workspace['targ_vel'])
		# 	print("TOA of hazardous target: ", eng.workspace['safety'])
		

	print("Elapsed time: ", str(time()-t_0))
	# print("Ending. Writing data to textfile...\n")
	# uRAD_USB_SDK11.turnOFF(ser)
	# sweeps = len(I)
	# samples = len(I[1])
	
	# with open(resultsFileName, 'w') as f:
	# 	for sweep in range(sweeps):
	# 		IQ_string = ''
	# 		for sample in range(samples):
	# 			IQ_string += '%d ' % I[sweep][sample]
	# 		for sample in range(samples):
	# 			IQ_string += '%d ' % Q[sweep][sample]
	# 		#f.write(IQ_string + '%1.3f\n' % t_i[sweep])
	# 		f.write(IQ_string +'\n')
	# print("Sweeps stored: ", str(sweeps))
	# print("Samples per sweep: ", str(samples))
	print("Complete.")
	
except KeyboardInterrupt:
	uRAD_USB_SDK11.turnOFF(ser)
	print("Interrupted.")
	exit()
