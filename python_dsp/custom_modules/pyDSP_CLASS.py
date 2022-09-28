# from cfar_lib import os_cfar
from operator import length_hint
from turtle import up
import os_cfar_v5
import numpy as np
from scipy.fft import fft

class DSP_2_PULSE:
	def __init__(self, win, n_fft, num_nul, half_train, half_guard, rank, nbins, bin_width, f_ax):
		self.win = win
		




	def dsp_2pulse(self, i_data1, q_data1, i_data2, q_data2):

		# SQUARE LAW DETECTOR
		# NOTE: last element in slice not included
		iq_u1 = np.power(i_data1[  0:200],2) + np.power(q_data1[  0:200],2)
		iq_d1 = np.power(i_data1[200:400],2) + np.power(q_data1[200:400],2)

		iq_u2 = np.power(i_data2[  0:200],2) + np.power(q_data2[  0:200],2)
		iq_d2 = np.power(i_data2[200:400],2) + np.power(q_data2[200:400],2)
		
		# TAYLOR WINDOW
		# SLL specified as positive
		iq_u1 = np.multiply(iq_u1, win)
		iq_d1 = np.multiply(iq_d1, win)

		iq_u2 = np.multiply(iq_u2, win)
		iq_d2 = np.multiply(iq_d2, win)


		# 512-point FFT
		IQ_UP1 = fft(iq_u1,n_fft)
		IQ_DN1 = fft(iq_d1,n_fft)

		IQ_UP2 = fft(iq_u2,n_fft)
		IQ_DN2 = fft(iq_d2,n_fft)

		# Halve FFTs
		IQ_UP1 = IQ_UP1[0:round(n_fft/2)]
		IQ_DN1 = IQ_DN1[round(n_fft/2):]

		IQ_UP2 = IQ_UP2[0:round(n_fft/2)]
		IQ_DN2 = IQ_DN2[round(n_fft/2):]

		# Null feedthrough
		IQ_UP1[0:num_nul-1] = 0
		IQ_DN1[len(IQ_DN1)-num_nul:] = 0

		IQ_UP2[0:num_nul-1] = 0
		IQ_DN2[len(IQ_DN2)-num_nul:] = 0

		# Reverse down sweep
		IQ_DN1 = np.flip(IQ_DN1)
		IQ_DN2 = np.flip(IQ_DN2)

		mean_u = np.mean([IQ_UP1,IQ_UP2], axis=0)
		mean_d = np.mean([IQ_DN1,IQ_DN2], axis=0)

		IQ_UP = np.subtract(IQ_UP2, mean_u)
		IQ_DN = np.subtract(IQ_DN2, mean_d)
		# print(np.shape(IQ_UP))

		# note the abs
		SOS = 1
		# -------------------- CFAR detection ---------------------------
		cfar_scale = 1 # additional scaling factor
		Pfa, os_pku, upth = os_cfar(half_train, half_guard, rank, SOS, abs(IQ_UP), cfar_scale)
		Pfa, os_pkd, dnth = os_cfar(half_train, half_guard, rank, SOS, abs(IQ_DN), cfar_scale)
		# np.log(upth, out=upth)
		# np.log(dnth, out=dnth)
		# np.log(abs(IQ_UP), out=IQ_UP)
		# np.log(abs(IQ_DN), out=IQ_DN)

		# upth = 20*np.log(upth)
		# dnth = 20*np.log(dnth)
		# IQ_UP = 20*np.log(abs(IQ_UP))
		# IQ_DN = 20*np.log(abs(IQ_DN))
		# os_pku = 20*np.log(abs(cfar_res_up))
		# os_pkd = 20*np.log(abs(cfar_res_dn))
		
		fbu = np.zeros(nbins)
		fbd = np.zeros(nbins)

		rg_array = np.zeros(nbins)
		# fd_array = np.zeros(nbins)
		sp_array = np.zeros(nbins)
		ratio = np.zeros(nbins)
		# sp_array_corrected = np.zeros(nbins)
		# beat_arr = np.zeros(nbins)

		safety_inv = 0
		safety = 0
		beat_min = 0
		beat_index = 0
		slope = 2.4e11
		c = 299792458
		
		lmda = 0.0125
		road_width = 2
		correction_factor = 3
		fd_max = 2.6667e3 # for max speed = 60km/h
		# ********************* beat extraction for multiple targets **************************
		for bin in range(nbins):
			# find beat in bin
			bin_slice_d = os_pkd[bin*bin_width:(bin+1)*bin_width]
			magd = np.amax(bin_slice_d)
			idx_d = np.argmax(bin_slice_d)
			
			beat_index = bin*bin_width + idx_d
			if magd != 0:
				fbd[bin] = f_ax[beat_index]
				# set up bin slice to range of expected beats
				# See freqs from 0 to index 15 - determined from 60kmh (VERIFY)
				# check if far enough from center
				if (beat_index>15):
					beat_min = beat_index - 15
					bin_slice_u = os_pku[beat_index - 15:beat_index]
				# if not, start from center
				else:
					beat_min = 1
					bin_slice_u = os_pku[1:beat_index]
					
				# index is index in the subset
				magu = np.amax(bin_slice_u)
				idx_u = np.argmax(bin_slice_u)
				if magu != 0:
					fbu[bin] = f_ax[beat_index - 15 + idx_u]

				
				# if both not DC
				if (fbu[bin] != 0 and fbd[bin] != 0):
					fd = -fbu[bin] + fbd[bin]
					# fd_array[bin] = fd/2
					
					# if less than max expected and filter clutter doppler
					# NOTE: this was removed as the beat window can be
					# adjusted to handle these cases. Max dopp already handled,
					# min can be handled similarly
					# For static detection, min must be 0
					# if ((abs(fd/2) < fd_max) and (fd/2 > 400)):

					# convert Doppler to speed. fd is twice the Doppler therefore
					# divide by 2
					# sp_array[bin] = fd*lmda/4
					# Note that fbd is now positive
					rg_array[bin] = c*(fbu[bin] + fbd[bin])/(4*slope)

					# ************* Angle correction *******************
					# Theta in radians
					theta = np.arcsin(road_width/rg_array[bin])*correction_factor

					# real_v = fd*lmda/(8*np.cos(theta))
					sp_array[bin] = fd*lmda/(8*np.cos(theta))
					
		# print(Pfa)
		# ********************* Safety Algorithm ***********************************
		np.divide(rg_array,sp_array, ratio, where=sp_array!=0)
		# t_safe = 3
		if (np.any(ratio<3)):
			# 1 indicates sweep contained target at unsafe distance
			# UPDATE: put the ratio/time into array to scale how
			# safe the turn is
			safety = min(ratio)
			# for colour map:
			safety_inv = 3-min(ratio)
			
		# log scale for display purposes
		return os_pku, os_pkd, upth, dnth, IQ_UP, IQ_DN, safety_inv, beat_index, beat_min, rg_array, sp_array
	# return cfar_res_up, cfar_res_dn, 20*np.log10(upth), 20*np.log10(dnth),\
	#      20*np.log10(abs(IQ_UP), 10),  20*np.log10(abs(IQ_DN))