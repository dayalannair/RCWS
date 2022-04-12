from bluedot.btcomm import BluetoothServer
from time import sleep
from signal import pause

def data_received(data):
    # separate USB and Pi uRAD data
    if data[0] == 'u':
        print("USB - {}".format(data))
        usb_results.write(data)
    else:
        print("Pi - {}".format(data))
        pi_results.write(data)

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

pi_results = open('bluetooth_data/pi_bt_results', 'w')
usb_results = open('bluetooth_data/usb_bt_results', 'w')
print("starting")
server.start()
print(server.server_address)
print("waiting for connection")

try:
    pause() # sleep process until signal received
except KeyboardInterrupt as e:
    server.send("0")
    print("cancelled by user")
finally:
    print("stopping")
    server.stop()
    pi_results.close()
    usb_results.close()
    
print("stopped")