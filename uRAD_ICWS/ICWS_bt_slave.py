#!/usr/bin/env python3

from bluedot.btcomm import BluetoothClient
from datetime import datetime
from time import sleep
from signal import pause

def data_received(data):
    if (data == "0"):
        print("Master program terminated. Closing...")
        c.disconnect()
        exit()
    print("recv - {}".format(data))

print("Connecting")
c = BluetoothClient("DC:A6:32:53:1F:9D", data_received)

print("Sending")
try:
    while True:
        c.send("hi {} \n".format(str(datetime.now())))
        sleep(1)
finally:
    c.disconnect()