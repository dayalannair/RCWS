# from cfar_lib import os_cfar
from CFAR import soca_cfar
import numpy as np
from scipy.fft import fft

def py_trig_dsp(i_data, q_data, twin, n_fft, num_nul, half_train, half_guard, nbins, bin_width, f_ax, SOS):
	
	# SQUARE LAW DETECTOR
	# NOTE: last element in slice not included
	iq_u = np.power(i_data[  0:200],2) + np.power(q_data[  0:200],2)
	iq_d = np.power(i_data[200:400],2) + np.power(q_data[200:400],2)

	# TAYLOR WINDOW
	# SLL specified as positive
	iq_u = np.multiply(iq_u, twin)
	iq_d = np.multiply(iq_d, twin)

	# 512-point FFT
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
	
	# note the abs
	# -------------------- CFAR detection ---------------------------
	# cfar_scale = 1 # additional scaling factor
	# cfar_up, upth = os_cfar(half_train, half_guard, rank, SOS, abs(IQ_UP), cfar_scale)
	# cfar_dn, dnth = os_cfar(half_train, half_guard, rank, SOS, abs(IQ_DN), cfar_scale)

	cfar_up, upth = soca_cfar(half_train, half_guard, SOS, abs(IQ_UP))
	cfar_dn, dnth = soca_cfar(half_train, half_guard, SOS, abs(IQ_DN))

	# np.log(upth, out=upth)
	# np.log(dnth, out=dnth)
	# np.log(abs(IQ_UP), out=IQ_UP)
	# np.log(abs(IQ_DN), out=IQ_DN)

	# upth = 20*np.log(upth)
	# dnth = 20*np.log(dnth)
	# IQ_UP = 20*np.log(abs(IQ_UP))
	# IQ_DN = 20*np.log(abs(IQ_DN))
	# cfar_up = 20*np.log(abs(cfar_res_up))
	# cfar_dn = 20*np.log(abs(cfar_res_dn))
	
	fbu = np.zeros(nbins)
	fbd = np.zeros(nbins)

	rg_array = np.zeros(nbins)
	# fd_array = np.zeros(nbins)
	sp_array = np.zeros(nbins)
	ratio = np.zeros(nbins)
	# sp_array_corrected = np.zeros(nbins)
	# beat_arr = np.zeros(nbins)

	# safety_inv = 0
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
		bin_slice_d = cfar_dn[bin*bin_width:(bin+1)*bin_width]
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
				bin_slice_u = cfar_up[beat_index - 15:beat_index]
			# if not, start from center
			else:
				beat_min = 1
				bin_slice_u = cfar_up[1:beat_index]
				
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
				if ((abs(fd/2) < fd_max) and (fd/2 > 400)):
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
		# safety_inv = 3-min(ratio)
		
	# log scale for display purposes
	return cfar_up, cfar_dn, upth, dnth, IQ_UP, IQ_DN, safety, beat_index, beat_min, rg_array, sp_array
	# return rg_array, sp_array, safety
	# return cfar_res_up, cfar_res_dn, 20*np.log10(upth), 20*np.log10(dnth),\
	#      20*np.log10(abs(IQ_UP), 10),  20*np.log10(abs(IQ_DN))


def range_speed_safety(i_data, q_data, twin, n_fft, num_nul, half_train, half_guard, nbins, bin_width, f_ax):

	# SQUARE LAW DETECTOR
	# NOTE: last element in slice not included
	iq_u = np.power(i_data[  0:200],2) + np.power(q_data[  0:200],2)
	iq_d = np.power(i_data[200:400],2) + np.power(q_data[200:400],2)

	# TAYLOR WINDOW
	# SLL specified as positive
	iq_u = np.multiply(iq_u, twin)
	iq_d = np.multiply(iq_d, twin)

	# 512-point FFT
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
	
	# -------------------- CFAR detection ---------------------------
	# cfar_scale = 1 # additional scaling factor
	# cfar_up, _ = os_cfar(half_train, half_guard, rank, SOS, abs(IQ_UP), cfar_scale)
	# cfar_dn, _ = os_cfar(half_train, half_guard, rank, SOS, abs(IQ_DN), cfar_scale)
	
	cfar_up, upth = soca_cfar(half_train, half_guard, SOS, abs(IQ_UP))
	cfar_dn, dnth = soca_cfar(half_train, half_guard, SOS, abs(IQ_DN))

	fbu = np.zeros(nbins)
	fbd = np.zeros(nbins)

	rg_array = np.zeros(nbins)
	sp_array = np.zeros(nbins)
	ratio = np.zeros(nbins)
	sp_array_corr = np.zeros(nbins)

	# safety_inv = 0
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
		bin_slice_d = cfar_dn[bin*bin_width:(bin+1)*bin_width]
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
				bin_slice_u = cfar_up[beat_index - 15:beat_index]
			# if not, start from center
			else:
				beat_min = 1
				bin_slice_u = cfar_up[1:beat_index]
				
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
				if (fd/2 > 400):
					# convert Doppler to speed. fd is twice the Doppler therefore
					# divide by 2
					sp_array[bin] = fd*lmda/4
					# Note that fbd is now positive
					rg_array[bin] = c*(fbu[bin] + fbd[bin])/(4*slope)

					# ************* Angle correction *******************
					# Theta in radians
					theta = np.arcsin(road_width/rg_array[bin])*correction_factor

					# # real_v = fd*lmda/(8*np.cos(theta))
					sp_array_corr[bin] = fd*lmda/(8*np.cos(theta))
				
	# print(Pfa)
	# ********************* Safety Algorithm ***********************************
	np.divide(rg_array,sp_array, ratio, where=sp_array!=0)
	# t_safe = 3
	if (np.any(ratio<3)):
		# 1 indicates sweep contained target at unsafe distance
		# UPDATE: put the ratio/time into array to scale how
		# safe the turn is
		safety = min(ratio)


	return rg_array, sp_array, safety, sp_array_corr
