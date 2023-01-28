import sys
sys.path.append('../custom_modules')
from load_data_lib import load_proc_data
import matplotlib.pyplot as plt
spMtx_l, spMtx_r, subset = load_proc_data()

len_subset = len(subset)

fig1, ax = plt.subplots(nrows=1, ncols=2, figsize=(10, 6)) #, constrained_layout=True)
fig1.tight_layout()
# set the spacing between subplots
# plt.subplots_adjust(left=0.1,
#                     bottom=0.1, 
#                     right=0.9, 
#                     top=0.9, 
#                     wspace=0.4, 
#                     hspace=0.4)

line1 = ax[0].imshow(spMtx_l, extent=[62.5, 0, 0, len_subset], origin='upper', vmin=0, vmax=70, aspect='auto')
ax[0].set_title("LHS Radar Time vs. Range vs. Speed")
# plt.grid(None)
# plt.show()
line2 = ax[1].imshow(spMtx_r, extent=[0, 62.5, 0, len_subset], origin='upper', vmin=0, vmax=70, aspect='auto') 
ax[1].set_title("LHS Radar Time vs. Range vs. Speed")
plt.show()
