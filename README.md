# Radar-based Vehicle Turn Safety System (VTSS)
Radar-based system used to determine turn safety for road vehicles.

# uRAD ICWS - Intersection Collision Warning System
This subsystem uses two uRAD radars: 1x uRAD USB v1.2, 1x uRAD RPi v1.1

## Single Pi
1. uRAD_ICWS_Pi_USB.py records data from both radars connected to host Pi

## Pi network

### Serial communication
In progress. Requires comms over USB or UART. Note that only a Pi Zero can work as a USB Gadget i.e. as a slave USB device.

### Bluetooth
1. ICWS_bt_slave.py sends data via bluetooth from both uRAD radars (connected to slave Pi) to master
2. ICWS_bt_master.py retrieves data via bluetooth from slave and stores in text files

### TCP/IP
This will be implemented if bluetooth not sufficient. Requires ethernet or wifi (less stable)
The goal is to use the most efficient and highest performing method of connecting two Pis. Bluetooth was the quickest to implement. 
Two Pis are needed so that the Acconeer radar system can be added. This is connected to the Pi 3/4. The uRADs can be run on a Pi Zero, as processing is done on the devices. The Acconeer requires many pins as it allows for up to 4 XR112 radars to be connected to the XC112 connector board

# Combined system

Since the Acconeer SDK is written in C and the uRAD SDK is written in Python, a Python program will be designed to execute the Acconeer C code within it.

# To do:
1. Complete MATLAB simulation
2. (Optional) FERS simulation
3. (Optional) compare MATLAB and FERS
4. Gather data
  1. Test pi Zero with 2x uRAD
  2. Test pi 4 with 2x uRAD
  3. Test bluetooth with pi 4 and pi Zero with 2x uRAD
  4. Test acconeer
  5. Test 3. with Acconeer
5. If bluetooth not performing well (packet loss/too slow etc.) try TCP/IP
6. compare results of each test to simulation/s

## Note on tests:
start small scale
1. Test with trolley + corner reflector and office chair
2. test with cars
3. test with camera - uRAD USB with android

# Additions
1. Pi Camera
2. Circuit with LED, Buzzer, switch for toggling system on/off (would link to car indicator)
3. GPS?
4. road mapping?
5. data collection?

# Test rigs

## Trolley with corner reflector
The corner reflector ensures a large amount of transmitted signal is reflected back towards the radar. The trolley will be tested with and without it to determine the increase in SNR. Since this is relatively close range, the radar should have no problem detecting the trolley without the corner reflector.

![alt text](https://github.com/dayalannair/RCWS/blob/master/test_rig_photos/trolley_front.jpg?raw=true)
![alt text](https://github.com/dayalannair/RCWS/blob/master/test_rig_photos/trolley_side.jpg?raw=true)

## Test 1: uRAD USB v1.2 on Pi Zero W
Trolley pushed straight towards radar. The road calculation was not added as the target's radial distance and velocity relative to the radar is the same as its actual d and v.

## Test 2: uRAD USB v1.2 on Android (with video)




