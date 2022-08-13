import sys

sys.path.append('../python_modules')

from time import time, sleep, strftime,localtime
from uRAD_DSP_lib import py_trig_dsp
import numpy as np
# True if USB, False if UART


for i in range(sweeps):
	# fetch IQ from uRAD USB

	safety_inv[i],rg_array[i], sp_array[i] = py_trig_dsp(I,Q)
	safety_inv_pi[i], rg_array_pi[i], sp_array_pi[i] = py_trig_dsp(I_pi,Q_pi)

	t1_proc = time()-t0_proc

	print("Processing time: ", t1_proc)

print("Elapsed time: ", str(time()-t_0))
print("Saving data...")
with open(fileName, 'w') as f:
	line = ''
	for s in range(sweeps):
		line = safety_inv[s] + ' ' + rg_array[s] + ' ' + sp_array[s]\
			+ safety_inv_pi[s] + ' ' + rg_array_pi[s] + ' ' + sp_array_pi[s]
		f.write(line +'\n')