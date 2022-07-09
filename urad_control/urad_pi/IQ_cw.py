import uRAD_RP_SDK10	# import the libray
from time import time, sleep, localtime, strftime

# input parameters
mode = 1	# doppler mode with best velocity accuracy
f0 = 125	# working at 24.125 GHz
BW = 0		# irrelevant parameter in this mode
Ns = 200	# 200 samples to have the best accuracy
Ntar = 4	# 4 target of interest
Vmax = 75	# searching along the full velocity range
MTI = 0		# irrelevant parameter due to the mode
Mth = 0		# parameter not used because "movement" is not requested

# results output array
velocity = [0] * Ntar
SNR = [0] * Ntar

# switch ON uRAD
uRAD_RP_SDK10.turnON()

# load the configuration
uRAD_RP_SDK10.loadConfiguration(mode, f0, BW, Ns, Ntar, Vmax, MTI, Mth)

I_cw = []
Q_cw = []
I = [0]*Ns
Q = [0]*Ns
sweeps = 256
t = localtime()
current_time = strftime("%H-%M-%S", t)  
fcw = "iq_CW_fmcw_" + current_time + ".txt"
try:
	print("Loop running...")
	for i in range(sweeps):
		uRAD_RP_SDK10.detection(0, 0, 0, I, Q, 0)
		I_cw.append(I)
		Q_cw.append(Q)
		print(I)

	print("Ending. Writing data to textfile...\n")
	uRAD_RP_SDK10.turnOFF()
	sweeps = len(I_cw)
	samples = len(I_cw[1])
	
	with open(fcw, 'w') as cw:
		for sweep in range(sweeps):
			IQ_string = ''
			for sample in range(samples):
				IQ_string += '%d ' % I_cw[sweep][sample]
			for sample in range(samples):
				IQ_string += '%d ' % Q_cw[sweep][sample]
			cw.write(IQ_string +'\n')
	print("Complete.")
	
except KeyboardInterrupt:
	uRAD_RP_SDK10.turnOFF()
	print("Interrupted.")
	exit()