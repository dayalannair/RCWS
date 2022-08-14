import sys

from pathlib import Path

file_path = Path(r"C:\Users\naird\OneDrive - University of Cape Town\RCWS_DATA\car_driveby\IQ_tri_20kmh.txt")


sys.path.append('../python_modules')
# sys.path.append('../../../../../OneDrive - University of Cape Town/RCWS_DATA/car_driveby')
from time import time
from uRAD_DSP_lib import py_trig_dsp
import numpy as np
from scipy.fft import fft
from scipy import signal
from os_cfar_v4 import os_cfar
# True if USB, False if UART
with open(file_path, "r") as raw_IQ:
		# split into sweeps
		sweeps = raw_IQ.read().split("\n")

subset = len(sweeps)-5000
fft_array       = np.empty([subset, 256])
threshold_array = np.empty([subset, 256])
up_peaks        = np.empty([subset, 256])

# ------------------------ Frequency axis -----------------
nfft = 512
n_fft = 512
Ns = 200
n_half = round(nfft/2)
fs = 200e3
# kHz Axis
fax = np.linspace(0, round(fs/2), round(n_half))
# c*fb/(2*slope)
tsweep = 1e-3
bw = 240e6
slope = bw/tsweep
c = 3e8
rng_ax = c*fax/(2*slope)

upth = np.full(n_half, 250)
dnth = np.full(n_half, 250)
fftu = np.full(n_half, 250)
fftd = np.full(n_half, 250)

twin = signal.windows.taylor(200, nbar=3, sll=100, norm=False)
nbins = 16

safety_inv = np.zeros(subset)
rg_array = np.zeros([subset, nbins])
sp_array = np.zeros([subset, nbins])
safety_fname = "safety_results.txt"
rng_fname = "range_results.txt"
spd_fname = "speed_results.txt"
t_0 = time()
for i in range(subset):
	# Extract samples from 1 sweep
	samples = np.array(sweeps[i].split(" "))
	i_data = samples[  0:400]
	q_data = samples[400:800]

	# 32 bit for embedded systems e.g. raspberry pi
	i_data = i_data.astype(np.int32)
	q_data = q_data.astype(np.int32)

	# t0_proc = time()

	safety_inv[i],rg_array[i], sp_array[i] = py_trig_dsp(i_data,q_data, twin, np, fft, os_cfar)

	# t1_proc = time()-t0_proc

	# print("Processing time: ", t1_proc)

print("Elapsed time: ", str(time()-t_0))
print("Saving data...")
np.savetxt(safety_fname,  safety_inv, fmt='%3.4f')
np.savetxt(rng_fname,  rg_array, fmt='%3.2f')
np.savetxt(spd_fname,  sp_array, fmt='%3.2f')

# with open(safety_fname, 'w') as f1, open(rng_fname, 'w') as f2,open(spd_fname, 'w') as f3:
# 	line = ''
# 	for s in range(subset):
# 		line = str(safety_inv[s]) + ' ' + str(rg_array[s]) + ' ' + str(sp_array[s])
		
# 		f.write(line +'\n')