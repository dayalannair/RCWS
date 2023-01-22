# Script for testing Python processing for a single uRAD
# on real data
# Once suitable, can assume it will operate the same
# in real time, though it could vary between scenarios/
# clutter backgrounds
# NOTE:
# Should also test with data from the dual radar system

import sys
sys.path.append('../custom_modules')
from time import time, sleep, strftime,localtime
import sys
from pyDSPv2 import py_trig_dsp, range_speed_safety
import numpy as np
import matplotlib as mpl
mpl.rcParams['path.simplify'] = True
mpl.rcParams['path.simplify_threshold'] = 1.0
mpl.rcParams['toolbar'] = 'None' 
mpl.rcParams["axes.grid"] = False
import matplotlib.style as mplstyle
mplstyle.use(['dark_background', 'ggplot', 'fast'])
import matplotlib.pyplot as plt
from scipy import signal
from pathlib import Path



# Home Desktop Proline i7 2nd Gen

# file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_20kmh.txt")
# file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_30kmh.txt")
# file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_40kmh.txt")
# file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_50kmh.txt")
file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_60kmh.txt")

# On laptop Yoga 910

# file_path = Path(r"C:\Users\Dayalan Nair\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_60kmh.txt")
# file_path = Path(r"C:\Users\Dayalan Nair\OneDrive - University of Cape Town\RCWS_DATA\")

# 60kmh subset
subset = range(800,1100)
# subset = range(0, 2000)

# 50 kmh subset - same
# 40 kmh subset
# subset = range(700,1100)
# 20km/h subset
# subset = range(1,1500)


len_subset = len(subset)

# sys.path.append('../../../../../OneDrive - University of Cape Town/RCWS_DATA/car_driveby')
with open(file_path, "r") as raw_IQ:
		# split into sweeps
		sweeps = raw_IQ.read().split("\n")

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
# rg_full = np.zeros(16*sweeps)
n_fft = 512
twin = signal.windows.taylor(200, nbar=3, sll=100, norm=False)
nul_width_factor = 0.04
num_nul = round((n_fft/2)*nul_width_factor)
# OS CFAR
ns = 200
# half_guard = n_fft/n_samples
# half_guard = int(np.floor(half_guard/2)*2) # make even

# half_train = round(20*n_fft/n_samples)
# half_train = int(np.floor(half_train/2))
# rank = 2*half_train -2*half_guard
# rank = half_train*2

# ======================================================
#					Tunable Parameters
# ======================================================
half_train = 8
half_guard = 7
Pfa = 0.08
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

# f_ax = np.linspace(0, round(fs/2), 256)
# print("Freq axis values: ", f_ax)
upth = np.zeros(256)
dnth = np.zeros(256)
fftu = np.zeros(256)
fftd = np.zeros(256)

# Ignore divide by zero
# numpy.seterr(divide = 'ignore')

# ===== LOG SCALE ==============
# upth = 20*np.log10(upth)
# dnth = 20*np.log10(dnth)
# fftu = 20*np.log10(abs(fftu))
# fftd = 20*np.log10(abs(fftd))
# os_pku = 20*np.log10(abs(os_pku))
# os_pkd = 20*np.log10(abs(os_pkd))

upth_2 = []
dnth_2 = []
fftd_2 = []
fftu_2 = []
rgMtx = np.zeros([len_subset, nbins])
spMtx = np.zeros([len_subset, nbins])
fbu = np.zeros([len_subset, nbins])
fbd = np.zeros([len_subset, nbins])

cfar_up = np.zeros([len_subset, 256])
cfar_dn = np.zeros([len_subset, 256])


scan_width = 10
calib = 1.2463

print("System running...")
# safety_inv = np.zeros(sweeps)
# safety_inv_2 = np.zeros(sweeps)
plt.pause(0.1)
# print(sweeps[800])
idx = 0
for i in subset:
	samples = np.array(sweeps[i].split(" "))
	i_data = samples[  0:400]
	q_data = samples[400:800]

	# 32 bit for embedded systems e.g. raspberry pi
	i_data = i_data.astype(np.int32)
	q_data = q_data.astype(np.int32)

	# _, _, upth, dnth, fftu, fftd, _, _, _,\
	# rgMtx[idx, :], spMtx[idx, :] = py_trig_dsp(i_data,q_data, twin, n_fft, num_nul, half_train, \
	# half_guard, nbins, bin_width, f_ax, SOS)


	rgMtx[idx, :], spMtx[idx, :], _, fbu[idx, :], fbd[idx, :], _, cfar_up[idx, :], cfar_dn[idx, :] = \
		range_speed_safety(i_data, q_data, twin, n_fft, num_nul, half_train, \
	half_guard, nbins, bin_width, f_ax, SOS, calib, scan_width)


	idx = idx + 1
	# spMtx[idx, :] = spMtx[idx, :]*3.6
	# print(spMtx[np.nonzero(spMtx)])

print("Saving data...")
spMtx = spMtx*3.6 # km/h
# safety_fname = "safety_results.txt"
rng_fname = "range_results.txt"
spd_fname = "speed_results.txt"
fbu_fname = "fbu_results.txt"
fbd_fname = "fbd_results.txt"
# np.savetxt(safety_fname,  safety, fmt='%3.4f')
np.savetxt(rng_fname,  rgMtx, fmt='%10.5f')
np.savetxt(spd_fname,  spMtx, fmt='%10.5f')
np.savetxt(fbu_fname,  fbu, fmt='%10.5f')
np.savetxt(fbd_fname,  fbd, fmt='%10.5f')

fd_arr = np.subtract(fbd, fbu)/2
fd_fname = "dopp_results.txt"
np.savetxt(fd_fname,  fbd, fmt='%10.5f')

cfu_fname = "cfar_u_results.txt"
cfd_fname = "cfar_d_results.txt"
# np.savetxt(safety_fname,  safety, fmt='%3.4f')
np.savetxt(cfu_fname,  cfar_up, fmt='%10.5f')
np.savetxt(cfd_fname,  cfar_dn, fmt='%10.5f')

print("Processing Complete. Displaying results...")

fig1, ax = plt.subplots(nrows=1, ncols=2, figsize=(10, 6)) #, constrained_layout=True)
fig1.tight_layout()
# set the spacing between subplots
# plt.subplots_adjust(left=0.1,
#                     bottom=0.1, 
#                     right=0.9, 
#                     top=0.9, 
#                     wspace=0.4, 
#                     hspace=0.4)

line1_2 = ax[0].imshow(rgMtx, extent=[0, 62.5, 0, len(subset)], origin='upper', vmin=0, vmax=70, aspect='auto')
# plt.grid(None)
# plt.show()
line2_2 = ax[1].imshow(spMtx, extent=[0, 62.5, 0, len(subset)], origin='upper', vmin=0, vmax=70, aspect='auto')
# plt.grid(None)
plt.show()


# fig1.canvas.draw()
input("Press any key to exit.")