
import uRAD_RP_SDK10		# uRAD v1.1 RPi lib
from time import time, sleep

# input parameters
mode = 3					# triangular. Try dual rate mode as well
f0 = 5						# start frequency 24.005 GHz
BW = 240					# sweep 240 MHz
Ns = 200					# 200 samples
Ntar = 1					# 2 target of interest
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

#Switch on Pi uRAD
uRAD_RP_SDK10.turnON()

# results output array for uRAD Pi
distance_pi = [0] * Ntar
SNR_pi = [0] * Ntar
velocity_pi = [0] * Ntar

# no return code from SDK 1.0 for RPi
uRAD_RP_SDK10.loadConfiguration(mode, f0, BW, Ns, Ntar, Rmax, MTI, Mth)

resultsPiFileName = 'uRAD_Pi_results.txt'
fileResultsPi = open(resultsPiFileName, 'a')
t_start = time()
prev_velocity = 0
iterations = 0
while True:
	try:
		t_sweep = time()
		# Extract results from Pi uRAD runnning SDK1.0
		uRAD_RP_SDK10.detection(distance_pi, velocity_pi, SNR_pi, 0, 0, 0)
		turn_safe = True

		if SNR_pi[0] > 0:
			#print("Pi Target: %d, Distance: %1.2f m, Velocity: %1.1f m/s, SNR: %1.1f dB" % (0+1, distance_pi[0], velocity_pi[0], SNR_pi[0]))
			fileResultsPi.write("%d %1.2f %1.1f %1.1f %1.3f\n" % (0+1, distance_pi[0], velocity_pi[0], SNR_pi[0], t_sweep))
			# if velocity_pi[0] != 0:
			# 	accel = (velocity_pi[0]-prev_velocity)/(t_sweep-t_start)
				#print('Fs %1.2f Hz, accel = %1.2f \n' % (1/(t_sweep-t_start), accel))
				# t_arrival = distance_pi[0]/velocity_pi[0]
				# this needs to be nested as velocity of 0 will keep t_arrival < t_accel
				# if (t_arrival < t_accel):
				# 	# turn unsafe if one target will arrive too soon
				# 	print("Turn unsafe Pi. Arrival time: %1.3f seconds" % t_arrival)
				# 	turn_safe = False
		iterations += 1

		if (iterations > 100):
		
		
			print('Fs %1.2f Hz' % (iterations/(t_sweep-t_start)))
			
		prev_velocity = velocity_pi[0]
		#print(" ")

	except KeyboardInterrupt:
		print("Exiting gracefully\n")
		uRAD_RP_SDK10.turnOFF()
		fileResultsPi.close()
		exit()

