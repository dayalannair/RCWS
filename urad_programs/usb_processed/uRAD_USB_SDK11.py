# uRAD_USB_SDK11.py - Library for controlling uRAD_USB-C radar
# Created by Victor Torres, Diego Gaston - uRAD 2020

import math
import struct

global configuration, NtarMax, get_distance, get_velocity, get_SNR, get_I, get_Q, get_movement, results_packetLen
NtarMax = 5
get_distance = False
get_velocity = False
get_SNR = False
get_I = False
get_Q = False
get_movement = False
results_packetLen = NtarMax*3*4+2

def loadConfiguration(ser, mode, f0, BW, Ns, Ntar, Rmax, MTI, Mth, Alpha, distance_true, velocity_true, SNR_true, I_true, Q_true, movement_true):

	global configuration, get_distance, get_velocity, get_SNR, get_I, get_Q, get_movement
	configuration = [0] * 8

	f0Min = 5
	f0Max = 195
	f0Max_CW = 245
	BWMin = 50
	BWMax = 240
	NsMin = 50
	NsMax = 200
	RmaxMax = 100
	VmaxMax = 75
	AlphaMin = 3
	AlphaMax = 25

	# Check correct values
	if ((mode == 0) or (mode > 4)):
		mode = 3
	if ((f0 > f0Max) and (mode != 1)):
		f0 = f0Min
	elif ((f0 > f0Max_CW) and (mode == 1)):
		f0 = f0Min
	elif (f0 < f0Min):
		f0 = f0Min
	BW_available = BWMax - f0 + f0Min
	if ((BW < BWMin) or (BW > BW_available)):
		BW = BW_available
	if ((Ns < NsMin) or (Ns > NsMax)):
		Ns = NsMax
	if ((Ntar == 0) or (Ntar > NtarMax)):
		Ntar = 1
	if ((mode != 1) and ((Rmax < 1) or (Rmax > RmaxMax))):
		Rmax = RmaxMax
	elif ((mode == 1) and (Rmax > VmaxMax)):
		Rmax = VmaxMax
	if ((MTI > 1) or (MTI < 0)):
		MTI = 0
	if ((Mth < 1) or Mth > 4):
		Mth = 4
	if (Alpha < AlphaMin):
		Alpha = AlphaMin
	elif (Alpha > AlphaMax):
		Alpha = AlphaMax
	Mth-=1
	
	# Create configuration register
	configuration[0] = ((mode << 5) + (f0 >> 3)) & 0b11111111
	configuration[1] = ((f0 << 5) + (BW >> 3)) & 0b11111111
	configuration[2] = ((BW << 5) + (Ns >> 3)) & 0b11111111
	configuration[3] = ((Ns << 5) + (Ntar << 2) + (Rmax >> 6)) & 0b11111111
	configuration[4] = ((Rmax << 2) + MTI) & 0b11111111 
	configuration[5] = (((Mth << 6) + (Alpha << 1)) & 0b11111111) + 0b00000001
	configuration[6] = 0
	if (distance_true):
		configuration[6] += 0b10000000
		get_distance = True
	if (velocity_true):
		configuration[6] += 0b01000000
		get_velocity = True
	if (SNR_true):
		configuration[6] += 0b00100000
		get_SNR = True
	if (I_true):
		configuration[6] += 0b00010000
		get_I = True
	if (Q_true):
		configuration[6] += 0b00001000
		get_Q = True
	if (movement_true):
		configuration[6] += 0b00000100
		get_movement = True

	CRC = ((configuration[0] + configuration[1] + configuration[2] + configuration[3] + configuration[4] + configuration[5] + configuration[6])) & 0b11111111
	configuration[7] = CRC

	try:
		if (ser.is_open):
			ser.write(bytearray([14]))
			ser.write(bytearray(configuration[0:8]))
			configuration[5] = configuration[5] & 0b11111110
			ACK = ser.read(1)
			if (ACK[0] == 0xAA):
				return 0
			else:
				return -1
		else:
			return -2
	except:
		return -3

def detection(ser):

	if (get_distance or get_velocity or get_SNR):
		NtarDetected = 0
		buff_temp = [0]*4
		distance = [0]*NtarMax
		velocity = [0]*NtarMax
		SNR = [0]*NtarMax
		movement = False
	else:
		NtarDetected = 0
		distance = []
		velocity = []
		SNR = []
		movement = False

	if (get_I or get_Q):
		mode = (configuration[0] & 0b11100000) >> 5
		Ns = ((configuration[2] & 0b00011111) << 3) + ((configuration[3] & 0b11100000) >> 5)
		Ns_temp = Ns
		if (mode == 3):
			Ns_temp *= 2
		elif (mode == 4):
			Ns_temp += Ns_temp + 2*math.ceil(0.75 * Ns_temp)
		if (get_I):
			I = [0]*Ns_temp
		else:
			I = []
		if (get_Q):
			Q = [0]*Ns_temp
		else:
			Q = []

	else:
		I = []
		Q = []

	try:
		if (ser.is_open):
			ser.write(bytearray([15]))
			if (get_distance or get_velocity or get_SNR or get_movement):
				# Receive results
				results = ser.read(results_packetLen)
				if (len(results) == results_packetLen):
					if (get_distance or get_velocity or get_SNR):
						Ntar_temp = (configuration[3] & 0b00011100) >> 2
						if (get_distance):
							distance[0:Ntar_temp] = struct.unpack('<%df' % Ntar_temp, results[0:4*Ntar_temp])
						if (get_velocity):
							velocity[0:Ntar_temp] = struct.unpack('<%df' % Ntar_temp, results[NtarMax*4:NtarMax*4+4*Ntar_temp])
						SNR[0:Ntar_temp] = struct.unpack('<%df' % Ntar_temp, results[2*NtarMax*4:2*NtarMax*4+4*Ntar_temp])
						NtarDetected = len([i for i in SNR if i > 0])
						if (not get_SNR):
							SNR = [0]*NtarMax
					if (get_movement):
						if (results[NtarMax*12] == 255):
							movement = True
				else:
					return -2, [], []

			# Receive I,Q
			if (get_I or get_Q):
				total_bytes = 0
				if (Ns % 2 == 0):
					total_bytes += Ns*1.5
					two_blocks_1 = math.floor(Ns*1.5/3)
				else:
					total_bytes += (Ns+1)*1.5
					two_blocks_1 = math.floor((Ns+1)*1.5/3)
				if (mode == 3 or mode == 4):
					two_blocks_2 = two_blocks_1
					total_bytes *= 2
				if (mode == 4):
					Ns_3 = math.ceil(0.75*Ns)
					if (Ns_3 % 2 == 0):
						total_bytes += 2*Ns_3*1.5
						two_blocks_3 = math.floor(Ns_3*1.5/3)
					else:
						total_bytes += 2*(Ns_3+1)*1.5
						two_blocks_3 = math.floor((Ns_3+1)*1.5/3)

				total_bytes = int(total_bytes)

			if (get_I):
				bufferIbytes = ser.read(total_bytes)
				if (len(bufferIbytes) == total_bytes):
					for i in range(two_blocks_1):
						I[i*2+0] = (bufferIbytes[i*3+0] << 4) + (bufferIbytes[i*3+1] >> 4)
						if (i*2+1 <= Ns-1):
							I[i*2+1] = ((bufferIbytes[i*3+1] & 15) << 8) + bufferIbytes[i*3+2]
					if (mode == 3 or mode == 4):
						for i in range(two_blocks_2):
							I[Ns+i*2+0] = (bufferIbytes[(two_blocks_1+i)*3+0] << 4) + (bufferIbytes[(two_blocks_1+i)*3+1] >> 4)
							if (Ns+i*2+1 <= 2*Ns-1):
								I[Ns+i*2+1] = ((bufferIbytes[(two_blocks_1+i)*3+1] & 15) << 8) + bufferIbytes[(two_blocks_1+i)*3+2]
						if (mode == 4):
							for i in range(two_blocks_3):
								I[2*Ns+i*2+0] = (bufferIbytes[(two_blocks_1+two_blocks_2+i)*3+0] << 4) + (bufferIbytes[(two_blocks_1+two_blocks_2+i)*3+1] >> 4)
								if (2*Ns+i*2+1 <= 2*Ns+Ns_3-1):
									I[2*Ns+i*2+1] = ((bufferIbytes[(two_blocks_1+two_blocks_2+i)*3+1] & 15) << 8) + bufferIbytes[(two_blocks_1+two_blocks_2+i)*3+2]
							for i in range(two_blocks_3):
								I[2*Ns+Ns_3+i*2+0] = (bufferIbytes[(two_blocks_1+two_blocks_2+two_blocks_3+i)*3+0] << 4) + (bufferIbytes[(two_blocks_1+two_blocks_2+two_blocks_3+i)*3+1] >> 4)
								if (2*Ns+Ns_3+i*2+1 <= 2*Ns+2*Ns_3-1):
									I[2*Ns+Ns_3+i*2+1] = ((bufferIbytes[(two_blocks_1+two_blocks_2+two_blocks_3+i)*3+1] & 15) << 8) + bufferIbytes[(two_blocks_1+two_blocks_2+two_blocks_3+i)*3+2]

				else:
					return -2, [], []

			if (get_Q):
				bufferQbytes = ser.read(total_bytes)
				if (len(bufferQbytes) == total_bytes):
					for i in range(two_blocks_1):
						Q[i*2+0] = (bufferQbytes[i*3+0] << 4) + (bufferQbytes[i*3+1] >> 4)
						if (i*2+1 <= Ns-1):
							Q[i*2+1] = ((bufferQbytes[i*3+1] & 15) << 8) + bufferQbytes[i*3+2]
					if (mode == 3 or mode == 4):
						for i in range(two_blocks_2):
							Q[Ns+i*2+0] = (bufferQbytes[(two_blocks_1+i)*3+0] << 4) + (bufferQbytes[(two_blocks_1+i)*3+1] >> 4)
							if (Ns+i*2+1 <= 2*Ns-1):
								Q[Ns+i*2+1] = ((bufferQbytes[(two_blocks_1+i)*3+1] & 15) << 8) + bufferQbytes[(two_blocks_1+i)*3+2]
						if (mode == 4):
							for i in range(two_blocks_3):
								Q[2*Ns+i*2+0] = (bufferQbytes[(two_blocks_1+two_blocks_2+i)*3+0] << 4) + (bufferQbytes[(two_blocks_1+two_blocks_2+i)*3+1] >> 4)
								if (2*Ns+i*2+1 <= 2*Ns+Ns_3-1):
									Q[2*Ns+i*2+1] = ((bufferQbytes[(two_blocks_1+two_blocks_2+i)*3+1] & 15) << 8) + bufferQbytes[(two_blocks_1+two_blocks_2+i)*3+2]
							for i in range(two_blocks_3):
								Q[2*Ns+Ns_3+i*2+0] = (bufferQbytes[(two_blocks_1+two_blocks_2+two_blocks_3+i)*3+0] << 4) + (bufferQbytes[(two_blocks_1+two_blocks_2+two_blocks_3+i)*3+1] >> 4)
								if (2*Ns+Ns_3+i*2+1 <= 2*Ns+2*Ns_3-1):
									Q[2*Ns+Ns_3+i*2+1] = ((bufferQbytes[(two_blocks_1+two_blocks_2+two_blocks_3+i)*3+1] & 15) << 8) + bufferQbytes[(two_blocks_1+two_blocks_2+two_blocks_3+i)*3+2]

				else:
					return -2, [], []

			return 0, [NtarDetected, distance, velocity, SNR, movement], [I, Q]
		else:
			return -1, [], []
	except:
		return -2, [], []

def turnON(ser):
	try:
		if (ser.is_open):
			ser.write(bytearray([16]))
			ACK = ser.read(1)
			if (ACK[0] == 0xAA):
				return 0
			else:
				return -1
		else:
			return -2
	except:
		return -3

def turnOFF(ser):
	try:
		if (ser.is_open):
			ser.write(bytearray([17]))
			ACK = ser.read(1)
			if (ACK[0] == 0xAA):
				return 0
			else:
				return -1
		else:
			return -2
	except:
		return -3
