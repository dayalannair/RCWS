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
from pyDSPv2 import py_trig_dsp, range_speed_safety
import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
from load_data_lib import load_dual_data
lhs, rhs, subset = load_dual_data()
len_subset = len(subset)
print("Subset length: ", str(len_subset))
fft_array       = np.empty([len_subset, 256])
threshold_array = np.empty([len_subset, 256])
up_peaks        = np.empty([len_subset, 256])

# input parameters
# BW and Ns input as arguments
f0 = 5						# starting at 24.005 GHz
I_true = True 				# In-Phase Component (RAW data) requested
Q_true = True 				# Quadrature Component (RAW data) requested

t_0 = time()
fs = 200e3
# ------------------------ Frequency axis -----------------
nfft = 512
# kHz Axis
fax = np.linspace(0, round(fs/2), round(nfft/2))
# c*fb/(2*slope)
tsweep = 1e-3
bw = 240e6
slope = bw/tsweep
c = 299792458
rng_ax = c*fax/(2*slope)
# rg_full = np.zeros(16*lhs)
n_fft = 512
twin = signal.windows.taylor(200, nbar=3, sll=100, norm=False)
nul_width_factor = 0.04
num_nul = round((n_fft/2)*nul_width_factor)
# OS CFAR
ns = 200
# ======================================================
#					Tunable Parameters
# ======================================================
half_train = 8
half_guard = 7
Pfa = 0.05
SOS = ns*(Pfa**(-1/ns)-1)
print("Pfa: ", str(Pfa))
print("CFAR alpha value: ", SOS)
nbins = 16
bin_width = round((n_fft/2)/nbins)
# tsweep = 1e-3
# bw = 240e6
# # can optimise out this calculation
# slope = bw/tsweep
fs = 200e3

delta_f = fs/n_fft
print('Frequency resolution: ',delta_f)

# Below matches matlab better than linspace
f_ax = np.arange(0, fs/2, delta_f, dtype=float)


rgMtx_l = np.zeros([len_subset, nbins])
spMtx_l = np.zeros([len_subset, nbins])
sfMtx_l = np.zeros(len_subset)

rgMtx_r = np.zeros([len_subset, nbins])
spMtx_r = np.zeros([len_subset, nbins])
sfMtx_r = np.zeros(len_subset)


scan_width = 10
calib = 1.2463

print("System running...")
# safety_inv = np.zeros(lhs)
# safety_inv_2 = np.zeros(lhs)
# print(lhs[800])
i = 0
for sweep in subset:
	lhs_sweep = np.array(lhs[sweep].split(" "))
	lhs_i = lhs_sweep[  0:400]
	lhs_q = lhs_sweep[400:800]

	rhs_sweep = np.array(rhs[sweep].split(" "))
	rhs_i = rhs_sweep[  0:400]
	rhs_q = rhs_sweep[400:800]

	# 32 bit for embedded systems e.g. raspberry pi
	lhs_i = lhs_i.astype(np.int32)
	lhs_q = lhs_q.astype(np.int32)
	rhs_i = rhs_i.astype(np.int32)
	rhs_q = rhs_q.astype(np.int32)

	# _, _, upth, dnth, fftu, fftd, _, _, _,\
	# rgMtx_l[i, :], spMtx_l[i, :] = py_trig_dsp(rhs_i,rhs_q, twin, n_fft, num_nul, half_train, \
	# half_guard, nbins, bin_width, f_ax, SOS)


	rgMtx_l[i, :], spMtx_l[i, :], sfMtx_l[i] = \
		range_speed_safety(lhs_i, lhs_q, twin, n_fft, num_nul, half_train, \
	half_guard,1, nbins, bin_width, f_ax, SOS, calib, scan_width)

	rgMtx_r[i, :], spMtx_r[i, :], sfMtx_r[i] = \
		range_speed_safety(rhs_i, rhs_q, twin, n_fft, num_nul, half_train, \
	half_guard,1, nbins, bin_width, f_ax, SOS, calib, scan_width)


	i = i + 1
	# spMtx_l[i, :] = spMtx_l[i, :]*3.6
	# print(spMtx_l[np.nonzero(spMtx_l)])
print("Saving data...")
spMtx_l = spMtx_l*3.6 # km/h
spMtx_r = spMtx_r*3.6 # km/h
# safety_fname = "safety_results.txt"
lhs_rng_fname = "lhs_range_results.txt"
lhs_spd_fname = "lhs_speed_results.txt"

rhs_rng_fname = "rhs_range_results.txt"
rhs_spd_fname = "rhs_speed_results.txt"

# np.savetxt(safety_fname,  safety, fmt='%3.4f')
np.savetxt(lhs_rng_fname,  rgMtx_l, fmt='%5.4f')
np.savetxt(lhs_spd_fname,  spMtx_l, fmt='%5.4f')

np.savetxt(rhs_rng_fname,  rgMtx_r, fmt='%5.4f')
np.savetxt(rhs_spd_fname,  spMtx_r, fmt='%5.4f')


print("Processing Complete. Displaying results...")

fig1, ax = plt.subplots(nrows=1, ncols=3, figsize=(10, 6)) #, constrained_layout=True)
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
line3, = ax[2].plot(sfMtx_l)
# thismanager = get_current_fig_manager()
# thismanager.window.SetPosition((500, 0))

# plt.grid(None)
plt.show()


# fig1.canvas.draw()
input("Press any key to exit.")