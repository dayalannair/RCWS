# ICPS
# Plotting of the recorded real time processed speed measurements
# Dayalan Nair
# April 2023

import sys
sys.path.append('../custom_modules')

from load_data_lib import load_proc_data
import matplotlib.pyplot as plt
import numpy as np
lhsSpd, rhsSpd, subset = load_proc_data()
timeStamps = np.linspace(0,30,2749)

len_subset = len(subset)
spMtxLhs = np.zeros([len_subset, 16])

for i in range(len_subset):
	spMtxLhs[i,:] = np.array(lhsSpd[i].split(" "))

timeStampsTrimmed = timeStamps[0:len_subset]
plt.imshow(spMtxLhs,cmap='terrain_r', origin='upper', vmin=0, vmax=70, aspect='auto', \
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
input("Press any key to exit.")
