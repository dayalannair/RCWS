# Radar Collision Warning System
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
