# from os_cfar_v4 import os_cfar
# import numpy as np
# from scipy.fft import fft

def py_trig_dsp(i_data, q_data, win, np, fft, os_cfar, n_fft, num_nul, half_guard, half_train, rank, SOS, cfar_scale, nbins, bin_width, f_ax):
# def py_trig_dsp(i_data, q_data):
	# SQUARE LAW DETECTOR
	# NOTE: last element in slice not included
	iq_u = np.power(i_data[  0:200],2) + np.power(q_data[  0:200],2)
	iq_d = np.power(i_data[200:400],2) + np.power(q_data[200:400],2)

	# TAYLOR WINDOW
	# SLL specified as positive
	iq_u = np.multiply(iq_u, win)
	iq_d = np.multiply(iq_d, win)

	# 512-point FFT
	# n_fft = 512 
	IQ_UP = fft(iq_u,n_fft)
	IQ_DN = fft(iq_d,n_fft)

	# Halve FFTs
	# note: python starts from zero for this!
	IQ_UP = IQ_UP[0:round(n_fft/2)]
	IQ_DN = IQ_DN[round(n_fft/2):]

	# print(len(IQ_UP))   
	# Null feedthrough
	# note: python starts from zero for this!
	IQ_UP[0:num_nul-1] = 0
	IQ_DN[len(IQ_DN)-num_nul:] = 0
	# print(len(IQ_UP))
	IQ_DN = np.flip(IQ_DN)
	# OS CFAR
	# n_samples = len(iq_u)
	# half_guard = n_fft/n_samples
	# half_guard = int(np.floor(half_guard/2)*2) # make even

	# half_train = round(20*n_fft/n_samples)
	# half_train = int(np.floor(half_train/2))
	# rank = 2*half_train -2*half_guard
	# rank = half_train*2
	# factorial needs integer values
	# note the abs
	# Scale used to increase threshold as SOS must be an integer
	
	# -------------------- CFAR detection ---------------------------
	Pfa, os_pku, upth = os_cfar(half_train, half_guard, rank, SOS, abs(IQ_UP), cfar_scale)
	Pfa, os_pkd, dnth = os_cfar(half_train, half_guard, rank, SOS, abs(IQ_DN), cfar_scale)
	# print(Pfa)
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
	

	rg_array = np.zeros(nbins)
	fd_array = np.zeros(nbins)
	sp_array = np.zeros(nbins)
	fs = 200e3
	lmda = 0.0125
	# tsweep = 1e-3
	# bw = 240e6
	# # can optimise out this calculation
	# slope = bw/tsweep
	slope = 2.4e11
	c = 3e8
	road_width = 2
	correction_factor = 3
	fd_max = 3e3 # for max speed = 60km/h
	safety_inv = 0
	safety = 0
	beat_min = 0
	beat_index = 0
	# ********************* beat extraction for multiple targets **************************
	for bin in range(nbins):
		# find beat in bin
		bin_slice_d = os_pkd[bin*bin_width:(bin+1)*bin_width]
		magd = np.amax(bin_slice_d)
		idx_d = np.argmax(bin_slice_d)
		
		beat_index = bin*bin_width + idx_d
		if magd != 0:
			fbd = f_ax[beat_index]
			# set up bin slice to range of expected beats
			# See freqs from 0 to index 15 - determined from 60kmh (VERIFY)
			# check if far enough from center
			if (beat_index>15):
				beat_min = beat_index - 15
				bin_slice_u = os_pku[beat_index - 15:beat_index]
			# if not, start from center
			else:
				beat_min = 1
				bin_slice_u = os_pku[0:beat_index]
				
			# index is index in the subset
			magu = np.amax(bin_slice_u)
			idx_u = np.argmax(bin_slice_u)
			if magu != 0:
				fbu = f_ax[beat_index - 15 + idx_u]
			else:
				fbu = 0
			
			# if both not DC
			if (fbu != 0 and fbd != 0):
				fd = -fbu + fbd
				fd_array[bin] = fd/2
				
				# if less than max expected and filter clutter doppler
				if ((abs(fd/2) < fd_max) and (fd/2 > 400)):
					# convert Doppler to speed. fd is twice the Doppler therefore
					# divide by 2
					# sp_array[bin] = fd*lmda/4
					# Note that fbd is now positive
					rg_array[bin] = c*(fbu + fbd)/(4*slope)

					# ************* Angle correction *******************
					# Theta in radians
					theta = np.arcsin(road_width/rg_array[bin])*correction_factor

					# real_v = fd*lmda/(8*np.cos(theta))
					sp_array[bin] = fd*lmda/(4*np.cos(theta))
				
	# print(Pfa)
	# ********************* Safety Algorithm ***********************************
	ratio = np.divide(rg_array,sp_array)
	# ratio = np.nan_to_num(ratio)
	t_safe = 3
	if (np.any(ratio<t_safe)):
		# print(ratio)
		# 1 indicates sweep contained target at unsafe distance
		# UPDATE: put the ratio/time into array to scale how
		# safe the turn is
		safety = np.nanmin(ratio)
		# for colour map:
		# safety_inv = t_safe-np.nanmin(ratio)
		
	# log scale for display purposes
	# 
	# return os_pku, os_pkd, upth, dnth, IQ_UP, IQ_DN, safety_inv, beat_index, beat_min, rg_array, sp_array
	# return cfar_res_up, cfar_res_dn, 20*np.log10(upth), 20*np.log10(dnth),\
	#      20*np.log10(abs(IQ_UP), 10),  20*np.log10(abs(IQ_DN))

	return safety, rg_array, sp_array