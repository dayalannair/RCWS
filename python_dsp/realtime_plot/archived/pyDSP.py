# from cfar_lib import os_cfar
from operator import length_hint
from turtle import up
from os_cfar_v2 import os_cfar
import numpy as np
from scipy.fft import fft
from scipy import signal

def py_trig_dsp(i_data, q_data):

    # SQUARE LAW DETECTOR
    # NOTE: last element in slice not included
    iq_u = np.power(i_data[  0:200],2) + np.power(q_data[  0:200],2)
    iq_d = np.power(i_data[200:400],2) + np.power(q_data[200:400],2)

    # TAYLOR WINDOW
    # SLL specified as positive
    twin = signal.windows.taylor(200, nbar=3, sll=100, norm=False)
    iq_u = np.multiply(iq_u, twin)
    iq_d = np.multiply(iq_d, twin)

    # 512-point FFT
    n_fft = 512 
    IQ_UP = fft(iq_u,n_fft)
    IQ_DN = fft(iq_d,n_fft)

    # Halve FFTs
    # note: python starts from zero for this!
    IQ_UP = IQ_UP[0:round(n_fft/2)]
    IQ_DN = IQ_DN[round(n_fft/2):]

    # print(len(IQ_UP))   
    # Null feedthrough
    nul_width_factor = 0.04
    num_nul = round((n_fft/2)*nul_width_factor)
    # note: python starts from zero for this!
    IQ_UP[0:num_nul-1] = 0
    IQ_DN[len(IQ_DN)-num_nul:] = 0
    # print(len(IQ_UP))
    IQ_DN = np.flip(IQ_DN)
    # OS CFAR
    n_samples = len(iq_u)
    half_guard = n_fft/n_samples
    half_guard = int(np.floor(half_guard/2)*2) # make even

    half_train = round(20*n_fft/n_samples)
    half_train = int(np.floor(half_train/2))
    rank = 2*half_train -2*half_guard
    # rank = half_train*2
    Pfa_expected = 15e-3
    # factorial needs integer values
    SOS = 2
    # note the abs

    Pfa, cfar_res_up, upth = os_cfar(half_train, half_guard, rank, SOS, abs(IQ_UP))
    Pfa, cfar_res_dn, dnth = os_cfar(half_train, half_guard, rank, SOS, abs(IQ_DN))

    # np.log(upth, out=upth)
    # np.log(dnth, out=dnth)
    # np.log(abs(IQ_UP), out=IQ_UP)
    # np.log(abs(IQ_DN), out=IQ_DN)

    upth = 20*np.log(upth)
    dnth = 20*np.log(dnth)
    IQ_UP = 20*np.log(abs(IQ_UP))
    IQ_DN = 20*np.log(abs(IQ_DN))
    cfar_res_up = 20*np.log(abs(cfar_res_up))
    cfar_res_dn = 20*np.log(abs(cfar_res_dn))

    # print(Pfa)


    # log scale for display purposes
    return cfar_res_up, cfar_res_dn, upth, dnth, IQ_UP, IQ_DN
    # return cfar_res_up, cfar_res_dn, 20*np.log10(upth), 20*np.log10(dnth),\
    #      20*np.log10(abs(IQ_UP), 10),  20*np.log10(abs(IQ_DN))