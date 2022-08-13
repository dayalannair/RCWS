# Test separate function processing

import matlab.engine
import numpy as np
print("Initialising MATLAB engine...")
eng = matlab.engine.start_matlab()
print("Configuring system parameters and MATLAB workspace...")
# Radar parameters
c = 3e8
fc = 24.005e9
lda = c/fc
tm = 1e-3
bw = 240e6
sweep_slope = bw/tm
Ns = 200
# Taylor window parameters
nbar = 4
sll = -38
# FFT parameters
nfft = 512
nul_width_factor = 0.04
num_nul = round((nfft/2)*nul_width_factor)
# OS CFAR parameters
guard = 2*nfft/Ns
guard = int(np.floor(guard/2)*2) # make even
train = round(20*nfft/Ns)
train = int(np.floor(train/2)*2)
rank = train
Pfa = 15e-3
# bin method
nbins = 16
bin_width = (nfft/2)/nbins
t_safe = 3
eng.workspace['lambda'] = lda
eng.workspace['k'] = sweep_slope
eng.workspace['Ns'] = Ns
eng.workspace['c'] = c

# twinu, twind = np.array(eng.proc_twin(nbar, sll, Ns, nargout=2))
# print(np.size(twinu), np.size(twind))
eng.workspace['twinu'], eng.workspace['twind'] = eng.proc_twin(nbar, sll, Ns, nargout=2)
eng.workspace['OS'] = eng.proc_oscfar(train, guard, rank, Pfa)
eng.workspace['f_neg'], eng.workspace['f_pos'] = eng.proc_faxis(nfft, nargout=2)

eng.workspace['n_fft'] = nfft
eng.workspace['nbins'] = nbins
eng.workspace['bin_width'] = bin_width
eng.workspace['t_safe'] = t_safe
eng.workspace['num_nul'] = num_nul

eng.workspace['i_data'] = [0]*400
eng.workspace['q_data'] = [0]*400
print("Testing sweep processing...")
eng.proc_triang_script(nargout=0)

# print(eng.workspace['OS'])
# print(eng.workspace['nbins'])
print(eng.workspace['safety'])