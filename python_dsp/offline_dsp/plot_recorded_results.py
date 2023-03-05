import sys
sys.path.append('../custom_modules')
from load_data_lib import load_proc_data
import matplotlib.pyplot as plt
import numpy as np
np.set_printoptions(threshold=sys.maxsize)
spMtx_l_flat, spMtx_r_flat, subset = load_proc_data()
len_subset = len(subset)

nbins = 16

rgMtx_l = np.zeros([len_subset, nbins])
spMtx_l = np.zeros([len_subset, nbins])
sfMtx_l = np.zeros(len_subset)

rgMtx_r = np.zeros([len_subset, nbins])
spMtx_r = np.zeros([len_subset, nbins])
sfMtx_r = np.zeros(len_subset)
# timeStamps = np.linspace(0,30,2749)

# print(timeStamps)

# print(np.shape(spMtx_l_flat[1]))
# print(spMtx_l_flat[1])
print(np.array(spMtx_l_flat[1].split(" ")))

for i in range(0, len_subset):
    spMtx_l[i, :] = np.array(spMtx_l_flat[i].split(" "))
    spMtx_r[i, :] = np.array(spMtx_r_flat[i].split(" "))

# spMtx_l = np.reshape(spMtx_l, [len_subset, 16])
# spMtx_r = np.reshape(spMtx_r, [len_subset, 16])
fig1, ax = plt.subplots(nrows=1, ncols=2, figsize=(10, 6)) #, constrained_layout=True)
fig1.tight_layout()
# set the spacing between subplots
# plt.subplots_adjust(left=0.1,
#                     bottom=0.1, 
#                     right=0.9, 
#                     top=0.9, 
#                     wspace=0.4, 
#                     hspace=0.4)
print(spMtx_r*3.6)
line1 = ax[0].imshow(spMtx_l*3.6, origin='upper', vmin=0, vmax=70, aspect='auto', interpolation='none',cmap='gist_ncar')
ax[0].set_title("LHS Radar Time vs. Range vs. Speed")
cbar1 = fig1.colorbar(line1, ax=ax[0])
# ax[0].invert_yaxis()
# plt.grid(None)

line2 = ax[1].imshow(spMtx_r*3.6,  origin='upper', vmin=0, vmax=70, aspect='auto', interpolation='none',cmap='gist_ncar') 
ax[1].set_title("RHS Radar Time vs. Range vs. Speed")
cbar2 = fig1.colorbar(line2, ax=ax[1])
# ax[1].invert_yaxis()
# plt.show()

plt.show()
input('Press enter to exit.')

# extent=[0, 62.5, 0, len_subset],