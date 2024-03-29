import sys
sys.path.append('../custom_modules')
from time import time, sleep, strftime,localtime
import sys
from pyDSPv2 import py_trig_dsp
import numpy as np
import matplotlib as mpl
mpl.rcParams['path.simplify'] = True
mpl.rcParams['path.simplify_threshold'] = 1.0
mpl.rcParams['toolbar'] = 'None' 
import matplotlib.style as mplstyle
mplstyle.use(['dark_background', 'ggplot', 'fast'])

from pathlib import Path

# file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_20kmh.txt")
# file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_30kmh.txt")
# file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_40kmh.txt")
# file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_50kmh.txt")
# file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_60kmh.txt")

# On laptop Yoga 910

file_path = Path(r"C:\Users\Dayalan Nair\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_60kmh.txt")
# file_path = Path(r"C:\Users\Dayalan Nair\OneDrive - University of Cape Town\RCWS_DATA\")

# 60kmh subset
subset = range(800,1100)
len_subset = len(subset)
# 50 kmh subset - same
# 40 kmh subset
# subset = range(700,1100)
# 20km/h subset
# subset = range(1,1500)

# sys.path.append('../../../../../OneDrive - University of Cape Town/RCWS_DATA/car_driveby')
with open(file_path, "r") as raw_IQ:
		# split into sweeps
		sweeps = raw_IQ.read().split("\n")

fft_array       = np.empty([len_subset, 256])
threshold_array = np.empty([len_subset, 256])
up_peaks        = np.empty([len_subset, 256])


import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec
from scipy import signal

import threading


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
twin = signal.windows.taylor(200, nbar=3, sll=150, norm=False)
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

half_train = 8
half_guard = 7

Pfa = 0.008
SOS = ns*(Pfa**(-1/ns)-1)
print("Pfa: ", str(Pfa))
print("CFAR alpha value: ", SOS)
# factorial needs integer values

nbins = 16
bin_width = round((n_fft/2)/nbins)

# tsweep = 1e-3
# bw = 240e6
# # can optimise out this calculation
# slope = bw/tsweep
fs = 200e3
f_ax = np.linspace(0, round(fs/2), round(n_fft/2))
plt.ion()
# print(beat_index)
# print(beat_min)
# plt.show(block=False)

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

fig1, ax = plt.subplots(nrows=4, ncols=1, figsize=(5, 6)) #, constrained_layout=True)
ax[0].set_xlim([0, 62.5])
ax[0].set_ylim([90, 180])
ax[1].set_xlim([0, 62.5])
ax[1].set_ylim([90, 180])
ax[2].set_xlim([0, 62.5])
ax[2].set_ylim([90, 180])
ax[3].set_xlim([0, 62.5])
ax[3].set_ylim([90, 180])

fig1.tight_layout()
# set the spacing between subplots
# plt.subplots_adjust(left=0.1,
#                     bottom=0.1, 
#                     right=0.9, 
#                     top=0.9, 
#                     wspace=0.4, 
#                     hspace=0.4)


upth_2 = []
dnth_2 = []
fftd_2 = []
fftu_2 = []
rgMtx = np.zeros([len(subset), nbins])
spMtx = np.zeros([len(subset), nbins])
line1_2 = ax[2].imshow(rgMtx, extent=[0, 62.5, 0, len(subset)], origin='upper', vmin=0, vmax=70)
line2_2 = ax[3].imshow(spMtx, extent=[0, 62.5, 0, len(subset)], origin='upper', vmin=0, vmax=70)

line1, = ax[0].plot(rng_ax, fftu)
line2, = ax[0].plot(rng_ax, upth)
line3, = ax[1].plot(rng_ax, fftd)
line4, = ax[1].plot(rng_ax, dnth)
# line1_2, = ax[2].plot(rng_ax, fftu)
# line2_2, = ax[2].plot(rng_ax, upth)
# line3_2, = ax[3].plot(rng_ax, fftd)
# line4_2, = ax[3].plot(rng_ax, dnth)

ax[0].set_title("USB Down chirp spectrum negative half flipped")
ax[1].set_title("USB Up chirp spectrum positive half")

ax[0].set_xlabel("Coupled Range (m)")
ax[1].set_xlabel("Coupled Range (m)")

ax[0].set_ylabel("Magnitude (dB)")
ax[1].set_ylabel("Magnitude (dB)")

ax[2].set_title("RPI Down chirp spectrum negative half flipped")
ax[3].set_title("RPI Up chirp spectrum positive half")

ax[2].set_xlabel("Coupled Range (m)")
ax[3].set_xlabel("Coupled Range (m)")

ax[2].set_ylabel("Magnitude (dB)")
ax[3].set_ylabel("Magnitude (dB)")


print("System running...")
# safety_inv = np.zeros(sweeps)
# safety_inv_2 = np.zeros(sweeps)
plt.pause(0.1)
bg1 = fig1.canvas.copy_from_bbox(fig1.bbox)

fig1.canvas.blit(fig1.bbox)
idx = 0
for i in subset:
	
	samples = np.array(sweeps[i].split(" "))
	i_data = samples[  0:400]
	q_data = samples[400:800]

	# 32 bit for embedded systems e.g. raspberry pi
	i_data = i_data.astype(np.int32)
	q_data = q_data.astype(np.int32)

	# t0_proc = time()
	_, _, upth, dnth, fftu, fftd, _, _, _,\
	rgMtx[idx, :], spMtx[idx, :] = py_trig_dsp(i_data,q_data, twin, n_fft, num_nul, half_train, \
	half_guard, nbins, bin_width, f_ax, SOS)
	idx = idx + 1
	fig1.canvas.restore_region(bg1)
	# print(len(cfar_res_up))
	# ============== LOG SCALE =====================
	line1.set_ydata(20*np.log10(abs(fftu + 10**-10)))
	line2.set_ydata(20*np.log10(upth + 10**-10))
	line3.set_ydata(20*np.log10(abs(fftd + 10**-10)))
	line4.set_ydata(20*np.log10(dnth + 10**-10))
	# # line5.set_ydata(os_pku)
	# # line6.set_ydata(os_pkd)
	line1_2.set_data(rgMtx)
	line2_2.set_data(spMtx)
	# line1_2.set_ydata(20*np.log10(abs(fftu_2)))
	# line2_2.set_ydata(20*np.log10(upth_2))
	# line3_2.set_ydata(20*np.log10(abs(fftd_2)))
	# line4_2.set_ydata(20*np.log10(dnth_2))
	# =============================================

	# NEED LOG SCALE
	# line1.set_ydata(fftu)
	# line2.set_ydata(upth)
	# line3.set_ydata(fftd)
	# line4.set_ydata(dnth)
	# line1_2.set_ydata(fftu_2)
	# line2_2.set_ydata(upth_2)
	# line3_2.set_ydata(fftd_2)
	# line4_2.set_ydata(dnth_2)

	# line9 = ax[1].axvline(rng_ax[beat_index])
	# line10 = ax[1].axvline(rng_ax[beat_min])
	# line9.remove()
	# line10.remove()
	
	ax[0].draw_artist(line1)
	ax[0].draw_artist(line2)
	ax[1].draw_artist(line3)
	ax[1].draw_artist(line4)

	# ax[2].draw_artist(line1_2)
	# ax[2].draw_artist(line2_2)
	# ax[3].draw_artist(line3_2)
	# ax[3].draw_artist(line4_2)
	fig1.canvas.blit(fig1.bbox)
	fig1.canvas.flush_events()
	# t1 = time() - t0