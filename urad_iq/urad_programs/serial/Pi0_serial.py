import serial

ser = serial.Serial()

ser.port = '/dev/ttyGS0'
ser.baudrate = 1e6

ser.bytesize = serial.EIGHTBITS
ser.parity = serial.PARITY_NONE
ser.stopbits = serial.STOPBITS_ONE



try:
	ser.open()
except:
	print("Could not open serial")
	exit()



