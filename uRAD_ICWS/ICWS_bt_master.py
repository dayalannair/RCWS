from bluedot.btcomm import BluetoothServer
from time import sleep
from signal import pause

def data_received(data):
    print("recv - {}".format(data))
    results.write(data)
    #server.send(data)

def client_connected():
    print("client connected")

def client_disconnected():
    print("client disconnected")

print("init")
server = BluetoothServer(
    data_received,
    auto_start = False,
    when_client_connects = client_connected,
    when_client_disconnects = client_disconnected)

results = open('bt_results', 'w')
print("starting")
server.start()
print(server.server_address)
print("waiting for connection")

# resultsUSBFileName = 'bluetooth_data/uRAD_USB_results.txt'
# fileResultsUSB = open(resultsUSBFileName, 'w')

# resultsPiFileName = 'bluetooth_data/uRAD_Pi_results.txt'
# fileResultsPi = open(resultsPiFileName, 'w')



try:
    pause() # sleep process until signal received
except KeyboardInterrupt as e:
    server.send("0")
    print("cancelled by user")
finally:
    print("stopping")
    server.stop()
    results.close()
    
print("stopped")