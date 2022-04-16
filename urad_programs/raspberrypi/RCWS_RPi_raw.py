
import uRAD_RP_SDK10		# uRAD v1.1 RPi lib
from time import time, sleep

# input parameters
mode = 3					# triangular. Try dual rate mode as well
f0 = 5						# start frequency 24.005 GHz
BW = 240					# sweep 240 MHz
Ns = 200					# 200 samples
Ntar = 1					# 2 target of interest
Rmax = 100					# searching along the full distance range
MTI = 0						# MTI mode enabled: only want information on moving targets
Mth = 1						# MTI threshold. Sets sensitivity with 4 being highest. Vary: find optimal for scenario
Alpha = 10					# signal has to be 10 dB higher than its surrounding. may need tuning
distance_true = False 		# request distance information
velocity_true = False		# request velocity information
SNR_true = False 			# Signal-to-Noise-Ratio information requested
I_true = True 				# In-Phase Component (RAW data) not requested
Q_true = True 				# Quadrature Component (RAW data) not requested
movement_true = False 		# not interested in boolean movement detection

# ICWS parameters
t_accel = 5					# time taken for host to match speed. Depends on car, chosen realistically (slow/normal turn)
t_arrival = 0				# time at which target vehicle is directly in front of host
turn_safe = True			# Indicates turn safety based on D and V of all targets detected
#safeDistance

#Switch on Pi uRAD
uRAD_RP_SDK10.turnON()

I = [0] * 2 * Ns
Q = [0] * 2 * Ns
# no return code from SDK 1.0 for RPi
uRAD_RP_SDK10.loadConfiguration(mode, f0, BW, Ns, Ntar, Rmax, MTI, Mth)

I_file = open('I.txt', 'w')
Q_file = open('Q.txt', 'w')

t_start = time()
prev_velocity = 0
iterations = 0
while True:
	try:
		t_sweep = time()
		uRAD_RP_SDK10.detection(0, 0, 0, I, Q, 0)

		I_string = ''
		Q_string = ''
		for index in range(len(I)):
			I_string += '%d ' % I[index]
		for index in range(len(Q)):
			Q_string += '%d ' % Q[index]

		I_file.write(I_string + '%1.3f\n' % t_sweep)
		Q_file.write(Q_string + '%1.3f\n' % t_sweep)
		iterations += 1
		#print("DAT %d %d %1.3f\n" % (I[0], Q[0], t_sweep)
		
		if (iterations > 100):
			print('Fs %1.2f Hz' % (iterations/(t_sweep-t_start)))

	except KeyboardInterrupt:
		print("Exiting gracefully\n")
		uRAD_RP_SDK10.turnOFF()
		I_file.close()
		Q_file.close()
		exit()

