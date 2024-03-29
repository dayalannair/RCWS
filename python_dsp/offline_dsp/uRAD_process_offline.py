import sys

from pathlib import Path

# file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_20kmh.txt")
# file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_30kmh.txt")
# file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_40kmh.txt")
# file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_50kmh.txt")
# file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_60kmh.txt")

# On laptop Yoga 910

file_path = Path(r"C:\Users\Dayalan Nair\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_60kmh.txt")


# 60kmh subset
subset = range(800,1100)
len_subset = len(subset)
# 50 kmh subset - same
# 40 kmh subset
# subset = range(700,1100)
# 20km/h subset
# subset = range(1,1500)

sys.path.append('../custom_modules')
# sys.path.append('../../../../../OneDrive - University of Cape Town/RCWS_DATA/car_driveby')
from time import time
from pyDSPv2 import py_trig_dsp
# global np
import numpy as np
from scipy.fft import fft
from scipy import signal
from os_cfar_v4 import os_cfar
# True if USB, False if UART
with open(file_path, "r") as raw_IQ:
		# split into sweeps
		sweeps = raw_IQ.read().split("\n")

fft_array       = np.empty([len_subset, 256])
threshold_array = np.empty([len_subset, 256])
up_peaks        = np.empty([len_subset, 256])

# ------------------------ Frequency axis -----------------
n_fft = 512
Ns = 200
n_half = round(n_fft/2)
fs = 200e3
# kHz Axis
f_ax = np.linspace(0, round(fs/2), round(n_half))
# c*fb/(2*slope)
tsweep = 1e-3
bw = 240e6
slope = bw/tsweep
c = 3e8

upth = np.full(n_half, 250)
dnth = np.full(n_half, 250)
fftu = np.full(n_half, 250)
fftd = np.full(n_half, 250)

twin = signal.windows.taylor(200, nbar=3, sll=100, norm=False)

nbins = 16
bin_width = round((n_fft/2)/nbins)

safety = np.zeros(len_subset)
rg_array = np.zeros([len_subset, nbins])
sp_array = np.zeros([len_subset, nbins])
safety_fname = "safety_results.txt"
rng_fname = "range_results.txt"
spd_fname = "speed_results.txt"

nul_width_factor = 0.04
num_nul = round((n_fft/2)*nul_width_factor)
print("NUM null = ", num_nul)

half_guard = 3
half_train = 32
rank = 2*half_train-2*half_guard
SOS = 2 # Pfa = 0.0056
cfar_scale = 1.4

t_0 = time()
data_index = 0
for i in subset:
	# Extract samples from 1 sweep
	samples = np.array(sweeps[i].split(" "))
	i_data = samples[  0:400]
	q_data = samples[400:800]

	# 32 bit for embedded systems e.g. raspberry pi
	i_data = i_data.astype(np.int32)
	q_data = q_data.astype(np.int32)

	# t0_proc = time()

	safety[data_index],rg_array[data_index], sp_array[data_index] = py_trig_dsp(i_data,q_data, twin, np, fft, os_cfar,\
		n_fft, num_nul, half_guard, half_train, rank, SOS, cfar_scale, nbins, bin_width, f_ax)

	data_index = data_index + 1
	# safety[i],rg_array[i], sp_array[i] = py_trig_dsp(i_data,q_data)
	# t1_proc = time()-t0_proc

	# print("Processing time: ", t1_proc)

print("Elapsed time: ", str(time()-t_0))
print("Saving data...")
np.savetxt(safety_fname,  safety, fmt='%3.4f')
np.savetxt(rng_fname,  rg_array, fmt='%3.2f')
np.savetxt(spd_fname,  sp_array, fmt='%3.2f')

# with open(safety_fname, 'w') as f1, open(rng_fname, 'w') as f2,open(spd_fname, 'w') as f3:
# 	line = ''
# 	for s in range(subset):
# 		line = str(safety[s]) + ' ' + str(rg_array[s]) + ' ' + str(sp_array[s])
		
# 		f.write(line +'\n')