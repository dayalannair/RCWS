# Script for testing Python processing for a single uRAD
# on real data
# Once suitable, can assume it will operate the same
# in real time, though it could vary between scenarios/
# clutter backgrounds
# NOTE:
# Should also test with data from the dual radar system

import sys
sys.path.append('../custom_modules')
import numpy as np
import matplotlib.pyplot as plt
from scipy import stats
# Parameters
fs = 200e3
n_fft = 1024
c = 299792458
tsweep = 1e-3
bw = 240e6
half_train = 16
half_guard = 14


# frequency and range axes
fpos = np.linspace(0, round(fs/2)-1, round(n_fft/2))
# negative axis flipped about y axis
fneg = np.linspace(round(fs/n_fft), round(fs/2), round(n_fft/2))
slope = bw/tsweep
rngAxPos = c*fpos/(2*slope)
rngAxNeg = c*fneg/(2*slope)

# Comparison test
# rng_fname1 = "range_results.txt"
spd_fname1 = "speed_results_20kmph.txt"
# rng_fname2 = "range_results.txt"
spd_fname2 = "speed_results_50kmph.txt"
# rng_fname3 = "range_results.txt"
spd_fname3 = "speed_results_60kmph.txt"
spMtx1 = np.loadtxt(spd_fname1,  delimiter=' ')
# rgMtx1 = np.loadtxt(rng_fname1,  delimiter=' ')
spMtx2 = np.loadtxt(spd_fname2,  delimiter=' ')
# rgMtx2 = np.loadtxt(rng_fname2,  delimiter=' ')
spMtx3 = np.loadtxt(spd_fname3,  delimiter=' ')
# rgMtx3 = np.loadtxt(rng_fname3,  delimiter=' ')

# Normal
# spd_fname1 = "speed_results_20kmph.txt"
spd_fname1 = "speed_results.txt"
spMtx1 = np.loadtxt(spd_fname1,  delimiter=' ')

print("Processing Complete. Displaying results...")

plt.tight_layout()
# 30-second burst
# duration = 30

# Sweeps only (deprecated)
# using update rate approx 92 Hz, and 4000 sweeps acquired,
# duration was either set to 45 seconds or sweeps were set to 4000
# Seems to be the later
lenSubset = np.shape(spMtx1)[0] 
duration = lenSubset/92

timeAxTicks = np.linspace(0, duration, 20)
rngAxTicks = np.linspace(0, np.max(rngAxNeg), 15)
plt.imshow(spMtx1, origin='upper', vmin=0, vmax=70, aspect='auto', \
		     interpolation='none', extent=[0, 62.5, duration, 0], cmap='terrain_r')
# plt.imshow((spMtx1+spMtx2+spMtx3), origin='upper', vmin=0, vmax=70, aspect='auto', \
# 		     interpolation='none', extent=[0, 62.5, duration, 0], cmap='terrain_r') #, extent=[0, 62.5, 0, len_subset]
# plt.imshow(spMtx2, origin='upper', vmin=0, vmax=70, aspect='auto', \
# 		     interpolation='none', extent=[0, 62.5, duration, 0], cmap='terrain_r') #, extent=[0, 62.5, 0, len_subset]
# plt.imshow(spMtx3, origin='upper', vmin=0, vmax=70, aspect='auto', \
# 		     interpolation='none', extent=[0, 62.5, duration, 0], cmap='terrain_r') #, extent=[0, 62.5, 0, len_subset]
plt.colorbar()
plt.grid()
plt.xticks(rngAxTicks)
plt.yticks(timeAxTicks)
# line3, = ax[1].plot(timeStampsTrimmed , sfVector)
# thismanager = get_current_fig_manager()
# thismanager.window.SetPosition((500, 0))
spMtxNoZeros = spMtx1[spMtx1 != 0]
# rgMtxNoZeros = rgMtx1[rgMtx1 != 0]

# distance = np.max(rgMtxNoZeros) - np.min(rgMtxNoZeros)
# t0 = np.argmax(rgMtxNoZeros)
# t1 = np.argmin(rgMtxNoZeros)
# deltaT = 
# print(t0)
# print(t1)
# print(spMtxNoZeros)
print(np.average(spMtxNoZeros, axis=None))
print(stats.mode(spMtxNoZeros, axis=None)[0])


plt.xlabel("Range (m)")
plt.ylabel("Time (s)")
# plt.grid(None)
plt.show()


# fig1.canvas.draw()
input("Press any key to exit.")