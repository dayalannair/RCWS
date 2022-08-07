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

    # -------------------- CFAR detection ---------------------------
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

    nbins = 16
    bin_width = (n_fft/2)/nbins
    fbu = np.zeros(n_sweeps,nbins)
    fbd = np.zeros(n_sweeps,nbins)

    rg_array = np.zeros(n_sweeps,nbins)
    fd_array = np.zeros(n_sweeps,nbins)
    sp_array = np.zeros(n_sweeps,nbins)
    sp_array_corrected = np.zeros(n_sweeps,nbins)
    beat_arr = np.zeros(n_sweeps,nbins)

    # ------------- beat extraction for multiple targets ----------
    for bin = 0:(nbins-1):
        # find beat in bin
        bin_slice_d = os_pkd(i,bin*bin_width+1:(bin+1)*bin_width)
        [magd, idx_d] = max(bin_slice_d)
        
        beat_index = bin*bin_width + idx_d
        if magd ~= 0:
            fbd(i,bin+1) = f_pos(beat_index)
            # set up bin slice to range of expected beats
            # See freqs from 0 to index 15 - determined from 60kmh (VERIFY)
            # check if far enough from center
            if (beat_index>15):
                bin_slice_u = os_pku(i,beat_index - 15:beat_index)
            # if not, start from center
            else:
                bin_slice_u = os_pku(i,1:beat_index)
            end
            # index is index in the subset
            [magu, idx_u] = max(bin_slice_u)
            if magu ~= 0:
                fbu(i,bin+1) = f_pos(beat_index - 15 + idx_u)
            end
            
            # if both not DC
            if and(fbu(i,bin+1) ~= 0, fbd(i,bin+1)~= 0):
                fd = -fbu(i,bin+1) + fbd(i,bin+1)
                fd_array(i,bin+1) = fd/2
                
                # if less than max expected and filter clutter doppler
                if ((abs(fd/2) < fd_max) && (fd/2 > 400)):
                    sp_array(i,bin+1) = dop2speed(fd/2,lambda)/2
                    rg_array(i,bin+1) = beat2range( ...
                        [fbu(i,bin+1) -fbd(i,bin+1)], k, c)

                    # Angle correction
                   
                    # Theta in radians
                    theta = asin(road_width/rg_array(i,bin+1))*correction_factor

                    real_v = dop2speed(fd/2,lambda)/(2*cos(theta))
                    sp_array_corrected(i,bin+1) = real_v
                
    # print(Pfa)


    # log scale for display purposes
    return cfar_res_up, cfar_res_dn, upth, dnth, IQ_UP, IQ_DN
    # return cfar_res_up, cfar_res_dn, 20*np.log10(upth), 20*np.log10(dnth),\
    #      20*np.log10(abs(IQ_UP), 10),  20*np.log10(abs(IQ_DN))