# ICPS
# Plotting of the recorded real time processed speed measurements
# Dayalan Nair
# April 2023

import sys
sys.path.append('../custom_modules')

from load_data_lib import load_proc_data
import matplotlib.pyplot as plt
import numpy as np
lhsSpd, rhsSpd, lhsRng, rhsRng, lhsSft, rhsSft, len_subset = load_proc_data()
timeStamps = np.linspace(0,30,len_subset)

print("Length: ", str(len_subset))
spMtxLhs = np.zeros([len_subset, 16])
spMtxRhs = np.zeros([len_subset, 16])
rgMtxLhs = np.zeros([len_subset, 16])
rgMtxRhs = np.zeros([len_subset, 16])

for i in range(len_subset-10):
	# print(lhsSpd[i])
	# print()
	# if(str(lhsSpd[i]) != ''):
	spMtxLhs[i,:] = np.array(lhsSpd[i].split(" "))
	spMtxRhs[i,:] = np.array(rhsSpd[i].split(" "))
	rgMtxLhs[i,:] = np.array(lhsRng[i].split(" "))
	rgMtxRhs[i,:] = np.array(rhsRng[i].split(" "))
spMtxLhs = spMtxLhs*3.6
spMtxRhs = spMtxRhs*3.6
spMtxLhs[spMtxLhs>60] = np.nan
spMtxRhs[spMtxRhs>60] = np.nan
timeStampsTrimmed = timeStamps[0:len_subset]
plt.figure(1)
plt.imshow(spMtxLhs,cmap='terrain_r', origin='upper', vmin=0, vmax=70, aspect='auto', \
		     interpolation='none', extent=[0, 62.5, np.max(timeStampsTrimmed), 0])
rngTicks = [0,5,10,15,20,25,30,35,40,45,50,55,60]
plt.xticks(rngTicks)
# plt.title("Left")
plt.xlabel("Range (m)")
plt.ylabel("Time (s)")
cbar = plt.colorbar()
cbar.set_label("Speed (km/h)")

plt.figure(2)
plt.imshow(spMtxRhs,cmap='terrain_r', origin='upper', vmin=0, vmax=70, aspect='auto', \
		     interpolation='none', extent=[0, 62.5, np.max(timeStampsTrimmed), 0])
rngTicks = [0,5,10,15,20,25,30,35,40,45,50,55,60]
plt.xticks(rngTicks)
plt.xlabel("Range (m)")
plt.ylabel("Time (s)")
cbar = plt.colorbar()
cbar.set_label("Speed (km/h)")

# =====================================================
# Range
# =====================================================
# plt.figure(1)
# plt.imshow(rgMtxLhs,cmap='terrain_r', origin='upper', vmin=0, vmax=70, aspect='auto', \
# 		     interpolation='none', extent=[0, 62.5, np.max(timeStampsTrimmed), 0])
# rngTicks = [0,5,10,15,20,25,30,35,40,45,50,55,60]
# plt.xticks(rngTicks)
# # plt.title("Left")
# plt.xlabel("Range (m)")
# plt.ylabel("Time (s)")
# cbar = plt.colorbar()
# cbar.set_label("Speed (km/h)")

# plt.figure(2)
# plt.imshow(rgMtxRhs,cmap='terrain_r', origin='upper', vmin=0, vmax=70, aspect='auto', \
# 		     interpolation='none', extent=[0, 62.5, np.max(timeStampsTrimmed), 0])
# rngTicks = [0,5,10,15,20,25,30,35,40,45,50,55,60]
# plt.xticks(rngTicks)
# plt.xlabel("Range (m)")
# plt.ylabel("Time (s)")
# cbar = plt.colorbar()
# cbar.set_label("Speed (km/h)")



# plt.figure(1)

# # # plt.plot(lhsSft)
# # # plt.figure(2)
# # # plt.plot(rhsSft)
# # # plt.show()

# plt.plot(rgMtxLhs)
# plt.figure(2)
# plt.plot(rgMtxRhs)

# plt.plot(spMtxLhs)
# plt.figure(2)
# plt.plot(spMtxRhs)
plt.show()

input("Press any key to exit.")
