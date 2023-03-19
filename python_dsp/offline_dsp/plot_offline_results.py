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

rng_fname = "range_results.txt"
spd_fname = "speed_results.txt"
spMtx = np.loadtxt(spd_fname,  delimiter=' ')


print("Processing Complete. Displaying results...")

plt.tight_layout()
# 30-second burst
duration = 30
timeAxTicks = np.linspace(0, 30, 14)
rngAxTicks = np.linspace(0, np.max(rngAxNeg), 15)
plt.imshow(spMtx, origin='upper', vmin=0, vmax=70, aspect='auto', \
		     interpolation='none', extent=[0, 62.5, 30, 0], cmap='terrain_r') #, extent=[0, 62.5, 0, len_subset]
plt.colorbar()

plt.xticks(rngAxTicks)
plt.yticks(timeAxTicks)
# line3, = ax[1].plot(timeStampsTrimmed , sfVector)
# thismanager = get_current_fig_manager()
# thismanager.window.SetPosition((500, 0))

plt.xlabel("Range (m)")
plt.ylabel("Time (s)")
# plt.grid(None)
plt.show()


# fig1.canvas.draw()
input("Press any key to exit.")