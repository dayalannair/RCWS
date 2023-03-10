import sys
sys.path.append('../custom_modules')
from time import time, sleep, strftime,localtime
import sys
from pyDSPv2 import py_trig_dsp
import numpy as np
import matplotlib.pyplot as plt
from load_data_lib import load_data
from scipy import signal
sweeps, subset = load_data()
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
# rg_full = np.zeros(16*sweeps)
n_fft = 512
ns = 200
win = signal.windows.taylor(ns, nbar=3, sll=100, norm=False)
# win = signal.windows.hanning(ns)
nul_width_factor = 0.04
num_nul = round((n_fft/2)*nul_width_factor)
# OS CFAR

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
print("Bin width: ", str(bin_width))

scan_width = 8
calib = 1.2463

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

fig1, ax = plt.subplots(nrows=2, ncols=2, figsize=(10, 6)) #, constrained_layout=True)
ax[0, 0].set_xlim([0, 62.5])
ax[0, 0].set_ylim([90, 180])
ax[1, 0].set_xlim([0, 62.5])
ax[1, 0].set_ylim([90, 180])
# ax[0, 1].set_xlim([0, 62.5])
# ax[0, 1].set_ylim([90, 180])
# ax[1, 1].set_xlim([0, 62.5])
# ax[1, 1].set_ylim([90, 180])


# uRAD GUI mean subtraction
# ax[0, 0].set_xlim([0, 62.5])
# ax[0, 0].set_ylim([-60, -13])
# ax[1, 0].set_xlim([0, 62.5])
# ax[1, 0].set_ylim([-60, -13])



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
rgMtx = np.zeros([len_subset, nbins])
spMtx = np.zeros([len_subset, nbins])
# line1_2 = ax[0, 1].imshow(rgMtx, extent=[0, 62.5, 0, len_subset*2], origin='upper', vmin=0, vmax=70)
# line2_2 = ax[1, 1].imshow(spMtx, extent=[0, 62.5, 0, len_subset*2], origin='upper', vmin=0, vmax=70)

line1_2 = ax[0, 1].imshow(rgMtx, extent=[0, 62.5, 0, len_subset], origin='upper', vmin=0, vmax=70, aspect='auto')
line2_2 = ax[1, 1].imshow(spMtx, extent=[0, 62.5, 0, len_subset], origin='upper', vmin=0, vmax=70, aspect='auto')

line1, = ax[0, 0].plot(rng_ax, fftu)
line2, = ax[0, 0].plot(rng_ax, upth)
line3, = ax[1, 0].plot(rng_ax, fftd)
line4, = ax[1, 0].plot(rng_ax, dnth)
# line1_2, = ax[2].plot(rng_ax, fftu)
# line2_2, = ax[2].plot(rng_ax, upth)
# line3_2, = ax[3].plot(rng_ax, fftd)
# line4_2, = ax[3].plot(rng_ax, dnth)

ax[0, 0].set_title("USB Down chirp spectrum negative half flipped")
ax[1, 0].set_title("USB Up chirp spectrum positive half")

ax[0, 0].set_xlabel("Coupled Range (m)")
ax[1, 0].set_xlabel("Coupled Range (m)")

ax[0, 0].set_ylabel("Magnitude (dB)")
ax[1, 0].set_ylabel("Magnitude (dB)")

ax[0, 1].set_title("RPI Down chirp spectrum negative half flipped")
ax[1, 1].set_title("RPI Up chirp spectrum positive half")

ax[0, 1].set_xlabel("Coupled Range (m)")
ax[1, 1].set_xlabel("Coupled Range (m)")

ax[0, 1].set_ylabel("Magnitude (dB)")
ax[1, 1].set_ylabel("Magnitude (dB)")


print("System running...")
# safety_inv = np.zeros(sweeps)
# safety_inv_2 = np.zeros(sweeps)
# plt.pause(0.1)

i = 0
for i in range(0, len_subset):
	samples = np.array(sweeps[i].split(" "))
	i_data = samples[  0:400]
	q_data = samples[400:800]

	# 32 bit for embedded systems e.g. raspberry pi
	i_data = i_data.astype(np.int32)
	q_data = q_data.astype(np.int32)

	t0_proc = time()
	_, _, upth, dnth, fftu, fftd, _, _, _,\
	rgMtx[i, :], spMtx[i, :] = py_trig_dsp(i_data,q_data, win, n_fft, num_nul, half_train, \
	half_guard, nbins, bin_width, f_ax, SOS, calib, scan_width)
	spMtx[i, :] = spMtx[i, :]*3.6
	t1_proc = time()

	print("Proc time: ", str(t1_proc-t0_proc))
	# print(spMtx[np.nonzero(spMtx)])
	# print(len(cfar_res_up))
	t0_plot = time()
	# ============== LOG SCALE =====================
	line1.set_ydata(20*np.log10(abs(fftu + 10**-10)))
	line2.set_ydata(20*np.log10(upth + 10**-10))
	line3.set_ydata(20*np.log10(abs(fftd + 10**-10)))
	line4.set_ydata(20*np.log10(dnth + 10**-10))
	# # line5.set_ydata(os_pku)
	# # line6.set_ydata(os_pkd)
	line1_2.set_data(rgMtx)
	line2_2.set_data(spMtx)

	# print("Max: ", np.max(20*np.log10(abs(fftu + 10**-10))))
	# print("Min: ", np.min(20*np.log10(abs(fftu + 10**-10))))

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

	# ax[2].draw_artist(line1_2)
	# ax[2].draw_artist(line2_2)
	# ax[3].draw_artist(line3_2)
	# ax[3].draw_artist(line4_2)
	fig1.canvas.draw()
	fig1.canvas.flush_events()
	# t1_plot = time()
	# print("Plot time: ", str(t1_plot - t0_plot))
	# t1 = time() - t0