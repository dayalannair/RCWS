# uRAD_RP_SDK10.py - Library for controlling uRAD SHIELD
# Created by Victor Torres, Diego Gaston - uRAD 2018

import spidev
from time import sleep, time
from gpiozero import OutputDevice
import struct
import math

PinTurnOn = OutputDevice(17)
SlaveSelect = OutputDevice(27)
PinTurnOn.off()
SlaveSelect.off()

spi = spidev.SpiDev() # Create spi object
spi_speed = 1000000

def turnON():
	PinTurnOn.on()

def turnOFF():
	PinTurnOn.off()

def loadConfiguration(mode, f0, BW, Ns, Ntar, Rmax, MTI, Mth):
	
	global configuration
	configuration = [0] * 8
	global NtarMax
	NtarMax = 5
	f0Min = 5
	f0Max = 195
	f0Max_CW = 245
	BWMin = 50
	BWMax = 240
	NsMin = 50
	NsMax = 200
	RmaxMax = 100
	VmaxMax = 75

	# Check correct values
	if ((mode == 0) or (mode > 4)): 
		mode = 3
	if ((f0 > f0Max) and (mode != 1)):
		f0 = f0Min
	elif ((f0 > f0Max_CW) and (mode == 1)):
		f0 = f0Min
	elif (f0 < f0Min):
		f0 = f0Min
	BW_available = BWMax - f0 + f0Min;
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
	if (MTI > 1):
		MTI = 0
	if ((Mth == 0) or Mth > 4):
		Mth = 4
	Mth -= 1
	
	# Create configuration register
	configuration[0] = ((mode << 5) + (f0 >> 3)) & 0b11111111
	configuration[1] = ((f0 << 5) + (BW >> 3)) & 0b11111111
	configuration[2] = ((BW << 5) + (Ns >> 3)) & 0b11111111
	configuration[3] = ((Ns << 5) + (Ntar << 2) + (Rmax >> 6)) & 0b11111111
	configuration[4] = ((Rmax << 2) + MTI) & 0b11111111 
	configuration[5] = (Mth << 6) + 0b00100000
	configuration[6] = 0
			
def detection(distance, velocity, SNR, bufferI, bufferQ, movement):

	# Variables
	code_configuration = [227]
	code_isready = [204]
	code_results = [199]
	code_I = [156]
	code_Q = [51]
	ACK = 170
	buff_temp = [0] * 4
	tx_1byte = [0]
	tx_results = [0] * (NtarMax*3*4+2)
	results = [0] * (NtarMax*3*4+2)
	error = False
	read_timeout = 0.200
	
	# SPI configuration
	spi.open(0,0) # open spi port 0, device (CS) 0
	spi.max_speed_hz = spi_speed
	spi.mode = 0b01 # mode of operation 0b[CPOL][CPHA]
	SlaveSelect.on()
	
	# Send configuration to uRAD
	configuration[6] = 0
	if (distance != 0):
		configuration[6] = 0b10000000
	if (velocity != 0):
		configuration[6] = configuration[6] + 0b01000000
	if (SNR != 0):
		configuration[6] = configuration[6] + 0b00100000
	if (bufferI != 0):
		configuration[6] = configuration[6] + 0b00010000
	if (bufferQ != 0):
		configuration[6] = configuration[6] + 0b00001000
	if (movement != 0):
		configuration[6] = configuration[6] + 0b00000100
	
	CRC = ((configuration[0] + configuration[1] + configuration[2] + configuration[3] + configuration[4] + configuration[5] + configuration[6])) & 0b11111111
	configuration[7] = CRC
	
	# Send configuration by SPI
	rx_ACK = [0]
	t0 = time()
	ti = time()
	while ((rx_ACK[0] != ACK) and ((ti-t0) < read_timeout)):
		SlaveSelect.off()
		sleep(0.0005)
		spi.xfer([code_configuration[0]])
		sleep(0.0005)
		spi.xfer([configuration[0], configuration[1], configuration[2], configuration[3], configuration[4], configuration[5], configuration[6], configuration[7]])
		sleep(0.0015)
		rx_ACK = spi.xfer(tx_1byte)
		SlaveSelect.on()
		sleep(0.0005)
		ti = time()

	if ((ti-t0) >= read_timeout):
		error = True
	if (distance != 0 or velocity != 0 or SNR != 0 or movement != 0):
		sleep(0.0200)

	if not error:
		rx_ACK = [0]
		while ((rx_ACK[0] != ACK) and ((ti-t0) < read_timeout)):
			SlaveSelect.off()
			#sleep(0.0010)
			spi.xfer([code_isready[0]])
			sleep(0.0015)
			rx_ACK = spi.xfer(tx_1byte)
			SlaveSelect.on()
			#sleep(0.0010)
			ti = time()

		if ((ti-t0) >= read_timeout):
			error = True
		
		if not error:

			configuration[5] = configuration[5] & 0b11011111;
			
			# Receive results
			if (distance != 0 or velocity != 0 or SNR != 0 or movement != 0):
				
				SlaveSelect.off()
				sleep(0.0005)
				spi.xfer([code_results[0]])
				sleep(0.0005)
				results = spi.xfer(tx_results)
				SlaveSelect.on()

				Ntar_temp = (configuration[3] & 0b00011100) >> 2
				for i in range(Ntar_temp):
					if (distance != 0):
						buff_temp[0] = results[i*4]
						buff_temp[1] = results[i*4+1]
						buff_temp[2] = results[i*4+2]
						buff_temp[3] = results[i*4+3]
						buff_temp_bytes = bytearray(buff_temp)
						temp = struct.unpack('<f', buff_temp_bytes)
						distance[i] = temp[0]
					if (velocity != 0):
						buff_temp[0] = results[NtarMax*4+i*4]
						buff_temp[1] = results[NtarMax*4+i*4+1]
						buff_temp[2] = results[NtarMax*4+i*4+2]
						buff_temp[3] = results[NtarMax*4+i*4+3]
						buff_temp_bytes = bytearray(buff_temp)
						temp = struct.unpack('<f', buff_temp_bytes)
						velocity[i] = temp[0]
					if (SNR != 0):
						buff_temp[0] = results[NtarMax*8+i*4]
						buff_temp[1] = results[NtarMax*8+i*4+1]
						buff_temp[2] = results[NtarMax*8+i*4+2]
						buff_temp[3] = results[NtarMax*8+i*4+3]
						buff_temp_bytes = bytearray(buff_temp)
						temp = struct.unpack('<f', buff_temp_bytes)
						SNR[i] = temp[0]
				if (movement != 0):
					if (results[NtarMax*12] == 255):
						movement[0] = True
					else:
						movement[0] = False

			mode_temp = (configuration[0] & 0b11100000) >> 5
			Ns_temp = ((configuration[2] & 0b00011111) << 3) + ((configuration[3] & 0b11100000) >> 5)
			if (mode_temp == 3):
				Ns_temp = 2 * Ns_temp
			elif (mode_temp == 4):
				Ns_temp = 2 * Ns_temp + 2 * math.ceil(0.75 * Ns_temp)

			# Receive I,Q
			tx_bufferIQ = [0] * (2 * Ns_temp)
			if (bufferI != 0):
				SlaveSelect.off()
				sleep(0.0005)
				spi.xfer([code_I[0]])
				sleep(0.0005)
				bufferI_SPI = spi.xfer(tx_bufferIQ)
				SlaveSelect.on()
				for i in range(Ns_temp):
					bufferI[i] = (bufferI_SPI[2*i+1] << 8) + bufferI_SPI[2*i]

			if (bufferQ != 0):
				SlaveSelect.off()
				sleep(0.0005)
				spi.xfer([code_Q[0]])
				sleep(0.0005)
				bufferQ_SPI = spi.xfer(tx_bufferIQ)
				SlaveSelect.on()
				for i in range(Ns_temp):
					bufferQ[i] = (bufferQ_SPI[2*i+1] << 8) + bufferQ_SPI[2*i]
		else:
			configuration[5] = configuration[5] & 0b11011111
			configuration[5] += 0b00100000
	else:
		configuration[5] = configuration[5] & 0b11011111
		configuration[5] += 0b00100000
	spi.close()
	return error
