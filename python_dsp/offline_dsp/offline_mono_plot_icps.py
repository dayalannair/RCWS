import sys
sys.path.append('../custom_modules')
from time import time
import sys
from pyDSPv2 import py_trig_dsp
import numpy as np
import matplotlib.pyplot as plt
from load_data_lib import load_data
from scipy import signal
sweeps, subset = load_data()
len_subset = len(subset)
print("Subset length: ", str(len_subset))

# Parameters
fs = 200e3
n_fft = 1024
c = 299792458
tsweep = 1e-3
bw = 240e6
half_train = 8
half_guard = 7

Pfa = 1e-6
nbins = 32
scan_width = 8
calib = 0.98
ns = 200

# Left radar angle adjustment
angOffsetMinRange = 7.1 
angOffset = 25*np.pi/180

# DC cancellation
max_voltage = 3.3
ADC_bits = 12
ADC_intervals = 2**ADC_bits
numVoltageLevels = max_voltage/ADC_intervals

# frequency and range axes
fpos = np.linspace(0, round(fs/2)-1, round(n_fft/2))
fneg = np.linspace(round(fs/n_fft), round(fs/2), round(n_fft/2))
# print(fpos)
# print(fneg)
slope = bw/tsweep
rngAxPos = c*fpos/(2*slope)
rngAxNeg = c*fneg/(2*slope)
rhs_road_width = 1.5

# win = signal.windows.taylor(ns, nbar=3, sll=40, norm=False)
win = np.ones(ns)
# OS CFAR

# half_guard = n_fft/n_samples
# half_guard = int(np.floor(half_guard/2)*2) # make even

# half_train = round(20*n_fft/n_samples)
# half_train = int(np.floor(half_train/2))
# rank = 2*half_train -2*half_guard
# rank = half_train*2

SOS = ns*(Pfa**(-1/ns)-1)

print("Pfa: ", str(Pfa))
print("CFAR alpha value: ", SOS)

bin_width = round((n_fft/2)/nbins)
print("Bin width: ", str(bin_width))

# Data structures
upth = np.zeros(round(n_fft/2))
dnth = np.zeros(round(n_fft/2))
fftu = np.zeros(round(n_fft/2))
fftd = np.zeros(round(n_fft/2))

# Interactive mode for updating data in loop
plt.ion()
# Configure plot
fig1, ax = plt.subplots(nrows=2, ncols=1, figsize=(10, 6))
fig1.tight_layout()
line1, = ax[0].plot(rngAxPos, fftu)
line2, = ax[0].plot(rngAxPos, upth)
line3, = ax[1].plot(rngAxNeg, fftd)
line4, = ax[1].plot(rngAxNeg, dnth)
# uRAD GUI mean subtraction
ax[0].set_xlim([0, 62.5])
ax[0].set_ylim([-60, 20])
ax[1].set_xlim([0, 62.5])
ax[1].set_ylim([-60, 20])
ax[0].set_title("USB Down chirp spectrum negative half flipped")
ax[1].set_title("USB Up chirp spectrum positive half")
ax[0].set_xlabel("Coupled Range (m)")
ax[1].set_xlabel("Coupled Range (m)")
ax[0].set_ylabel("Magnitude (dB)")
ax[1].set_ylabel("Magnitude (dB)")

for sweep in subset:
	samples = np.array(sweeps[sweep].split(" "))
	i_data = samples[  0:400]
	q_data = samples[400:800]

	# 32 bit for embedded systems e.g. raspberry pi
	i_data = i_data.astype(np.int32)
	q_data = q_data.astype(np.int32)

	t0_proc = time()
	_, _, upth, dnth, fftu, fftd, _, _, _,\
	_, _ = py_trig_dsp(i_data,q_data, win, n_fft, half_train, \
	half_guard, nbins, bin_width, fpos, fneg, SOS, calib, scan_width, angOffsetMinRange, \
	angOffset, numVoltageLevels, rhs_road_width)

	
	
	# t1_proc = time()

	# print("Proc time: ", str(t1_proc-t0_proc))

	# t0_plot = time()

	line1.set_ydata(20*np.log10(abs(fftu + 10**-10)))
	line2.set_ydata(20*np.log10(np.sqrt(upth) + 10**-10))
	line3.set_ydata(20*np.log10(abs(fftd + 10**-10)))
	line4.set_ydata(20*np.log10(np.sqrt(dnth) + 10**-10))

	# print("Max: ", np.max(20*np.log10(abs(fftu + 10**-10))))
	# print("Min: ", np.min(20*np.log10(abs(fftu + 10**-10))))

	
	fig1.canvas.draw()
	fig1.canvas.flush_events()
	# t1_plot = time()
	# print("Plot time: ", str(t1_plot - t0_plot))
	# t1 = time() - t0