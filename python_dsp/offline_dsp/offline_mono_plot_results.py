# Script for testing Python processing for a single uRAD
# on real data
# Once suitable, can assume it will operate the same
# in real time, though it could vary between scenarios/
# clutter backgrounds
# NOTE:
# Should also test with data from the dual radar system

import sys
sys.path.append('../custom_modules')
from time import time #, sleep, strftime,localtime
import sys
from pyDSPv2 import py_trig_dsp
import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
from load_data_lib import load_data
sweeps, subset = load_data()
len_subset = len(subset)
print("Subset length: ", str(len_subset))
# Parameters
fs = 200e3
n_fft = 1024
c = 299792458
tsweep = 1e-3
bw = 240e6
half_train = 16
half_guard = 14

Pfa = 9e-3
nbins = 32
scan_width = 32
calib = 0.9837
ns = 200

# Right radar angle correction
rhs_road_width = 1.5
angOffsetMinRange = 100 

# Left radar angle adjustment and correction
# angOffsetMinRange = 7.1 
angOffset = 25*np.pi/180

# DC cancellation
max_voltage = 3.3
ADC_bits = 12
ADC_intervals = 2**ADC_bits
numVoltageLevels = max_voltage/ADC_intervals

# frequency and range axes
fpos = np.linspace(0, round(fs/2)-1, round(n_fft/2))
# negative axis flipped about y axis
fneg = np.linspace(round(fs/n_fft), round(fs/2), round(n_fft/2))
# print(fpos)
# print(fneg)
slope = bw/tsweep
rngAxPos = c*fpos/(2*slope)
rngAxNeg = c*fneg/(2*slope)


win = signal.windows.taylor(ns, nbar=3, sll=40, norm=False)

# OS CFAR

# half_guard = n_fft/n_samples
# half_guard = int(np.floor(half_guard/2)*2) # make even

# half_train = round(20*n_fft/n_samples)
# half_train = int(np.floor(half_train/2))
# rank = 2*half_train -2*half_guard
# rank = half_train*2

SOS = ns*(Pfa**(-1/ns)-1)

print("Pfa: ", str(Pfa))
print("CFAR alpha value: ", SOS)

bin_width = round((n_fft/2)/nbins)
print("Bin width: ", str(bin_width))

plt.ion()

# Data structures
rgMtx = np.full([len_subset, nbins],np.nan)
spMtx = np.full([len_subset, nbins],np.nan)
sfVector = np.full(len_subset,np.nan)
timeStamps = np.linspace(0,30,2749)

print("Processing...")
# safety_inv = np.zeros(sweeps)
# safety_inv_2 = np.zeros(sweeps)
plt.pause(0.1)
# print(sweeps[800])
i = 0
for sweep in subset:
	samples = np.array(sweeps[sweep].split(" "))
	i_data = samples[  0:400]
	q_data = samples[400:800]

	# 32 bit for embedded systems e.g. raspberry pi
	i_data = i_data.astype(np.int32)
	q_data = q_data.astype(np.int32)

	# _, _, upth, dnth, fftu, fftd, _, _, _,\
	# rgMtx[i, :], spMtx[i, :] = py_trig_dsp(i_data,q_data, win, n_fft, num_nul, half_train, \
	# half_guard, nbins, bin_width, f_ax, SOS)


	_,_,_,_,_,_,_,_,rgMtx[i, :], spMtx[i, :], sfVector[i] = \
		py_trig_dsp(i_data,q_data, win, n_fft, half_train, \
	half_guard, nbins, bin_width, fpos, fneg, SOS, calib, scan_width, angOffsetMinRange, \
	angOffset, numVoltageLevels, rhs_road_width)


	
	# rgMtx[i, :], spMtx[i, :], sfVector[i], fbu[i, :], fbd[i, :], _, cfar_up[i, :], cfar_dn[i, :] = \
	# 	range_speed_safety(i_data, q_data, win, n_fft, num_nul, half_train, \
	# half_guard, 0,nbins, bin_width, f_ax, SOS, calib, scan_width)


	i = i + 1
	# spMtx[i, :] = spMtx[i, :]*3.6
	# print(spMtx[np.nonzero(spMtx)])
# print(sfVector)
print("Saving data...")
spMtx = spMtx*3.6 # km/h
# safety_fname = "safety_results.txt"
rng_fname = "range_results.txt"
spd_fname = "speed_results.txt"
fbu_fname = "fbu_results.txt"
fbd_fname = "fbd_results.txt"
# np.savetxt(safety_fname,  safety, fmt='%3.4f')
# np.savetxt(rng_fname,  rgMtx, fmt='%10.5f')
# np.savetxt(spd_fname,  spMtx, fmt='%10.5f')
# np.savetxt(fbu_fname,  fbu, fmt='%10.5f')
# np.savetxt(fbd_fname,  fbd, fmt='%10.5f')

np.savetxt(rng_fname,  rgMtx, fmt='%.2f')
np.savetxt(spd_fname,  spMtx, fmt='%.2f')
# np.savetxt(fbu_fname,  fbu, fmt='%.2f')
# np.savetxt(fbd_fname,  fbd, fmt='%.2f')


# fd_arr = np.subtract(fbd, fbu)/2
fd_fname = "dopp_results.txt"
# np.savetxt(fd_fname,  fbd, fmt='%10.5f')

# cfu_fname = "cfar_u_results.txt"
# cfd_fname = "cfar_d_results.txt"
# # np.savetxt(safety_fname,  safety, fmt='%3.4f')
# np.savetxt(cfu_fname,  cfar_up, fmt='%10.5f')
# np.savetxt(cfd_fname,  cfar_dn, fmt='%10.5f')

print("Processing Complete. Displaying results...")

# fig1, ax = plt.subplots(nrows=1, ncols=1, figsize=(10, 6)) #, constrained_layout=True)
plt.tight_layout()
# set the spacing between subplots
# plt.subplots_adjust(left=0.1,
#                     bottom=0.1, 
#                     right=0.9, 
#                     top=0.9, 
#                     wspace=0.4, 
#                     hspace=0.4)

# line1 = ax[0].imshow(rgMtx, origin='upper', vmin=0, vmax=70, aspect='auto', interpolation='none')#, extent=[0, 62.5, 0, len_subset]
# plt.grid(None)
# plt.show()
timeStampsTrimmed = timeStamps[0:len_subset]
# timeAxTicks = np.linspace(0, duration, 20)
# rngAxTicks = np.linspace(0, np.max(rngAxNeg), 15)

rngAxBins = np.linspace(0, np.max(rngAxNeg), 10)

plt.imshow(spMtx,cmap='terrain_r', origin='upper', vmin=0, vmax=70, aspect='auto', \
		     interpolation='none', extent=[0, 62.5, np.max(timeStampsTrimmed), 0]) #, extent=[0, 62.5, 0, len_subset]
# line3, = ax[1].plot(timeStampsTrimmed , sfVector)
# thismanager = get_current_fig_manager()
# thismanager.window.SetPosition((500, 0))
rngTicks = [0,5,10,15,20,25,30,35,40,45,50,55,60]
plt.xticks(rngTicks)
plt.xlabel("Range (m)")
plt.ylabel("Time (s)")
cbar = plt.colorbar()
cbar.set_label("Speed (km/h)")
# plt.grid(None)
plt.show()


# fig1.canvas.draw()
input("Press any key to exit.")