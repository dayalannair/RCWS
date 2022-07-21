import numpy as np
import scipy as sc

def process(i_data, q_data):
    # Parameters
    fc = 24.005e9
    c = 3e8
    lmda = c/fc
    tm = 1e-3
    bw = 240e6
    k = bw/tm
    Ns = 200

    # Square law detector
    iq_u = np.power(i_data[  1:200],2) + np.power(q_data[  1:200],2)
    iq_d = np.power(i_data[201:400],2) + np.power(q_data[201:400],2)

    # Taylor window
    nbar = 4
    sll = -38
    twinu = sc.signal.windows.taylor(Ns, nbar, sll)
    twind = sc.signal.windows.taylor(Ns, nbar, sll)
    iq_u = np.multiply(iq_u, np.transpose(twinu))
    iq_d = np.multiply(iq_d, np.transpose(twind))

    # FFT
    n_fft = 512 
    IQ_UP = np.fft.fft(iq_u,n_fft)
    IQ_DN = np.fft.fft(iq_d,n_fft)
    
    # Halve FFTs
    IQ_UP = IQ_UP[1:n_fft/2]
    IQ_DN = IQ_DN[n_fft/2+1:]
    
    # Null feedthrough
    nul_width_factor = 0.04
    num_nul = round((n_fft/2)*nul_width_factor)
    IQ_UP[1:num_nul] = 0
    IQ_DN[len(IQ_DN)-num_nul+1:] = 0
    





