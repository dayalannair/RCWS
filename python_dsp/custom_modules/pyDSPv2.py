# from cfar_lib import os_cfar
from CFAR import soca_cfar_far_edge, soca_cfar_edge, os_cfar_edge, goca_cfar_edge, ca_cfar_edge
import numpy as np
from scipy.fft import fft
import matplotlib.pyplot as plt

# NOTE: Range, speed, and possibly safety results of the below are not correct
def py_trig_dsp(i_data, q_data, windowCoeffs, n_fft, half_train, half_guard, \
		nbins, bin_width, fpos, fneg, SOS, calib, scan_width, \
			angOffsetMinRange, angOffset, NVL, road_width):


	i_u = np.subtract(np.multiply(i_data[  0:200], NVL), np.mean(np.multiply(i_data[  0:200], NVL)))
	i_d = np.subtract(np.multiply(i_data[200:400], NVL), np.mean(np.multiply(i_data[200:400], NVL)))
	q_u = np.subtract(np.multiply(q_data[  0:200], NVL), np.mean(np.multiply(q_data[  0:200], NVL)))
	q_d = np.subtract(np.multiply(q_data[200:400], NVL), np.mean(np.multiply(q_data[200:400], NVL)))
	
	# i_u = np.multiply(i_data[  0:200], NVL)
	# i_d = np.multiply(i_data[200:400], NVL)
	# q_u = np.multiply(q_data[  0:200], NVL)
	# q_d = np.multiply(q_data[200:400], NVL)
	

	# Window signal
	iq_u = np.multiply(i_u + 1j*q_u, windowCoeffs)
	iq_d = np.multiply(i_d + 1j*q_d, windowCoeffs)

	# FFT
	FFT_U = fft(iq_u,n_fft)
	FFT_D = fft(iq_d,n_fft)
	# plt.plot(20*np.log10(np.abs(FFT_D)))
	# plt.ylim()
	# plt.xlim([0,1024])
	# plt.show()
	# plt.pause(100)
	
	# Halve FFTs
	half_n_fft = int(n_fft/2)
	FFT_U = FFT_U[0:half_n_fft]
	FFT_D = FFT_D[half_n_fft:]
	FFT_D = np.flip(FFT_D)
	# plt.plot(20*np.log10(np.abs(FFT_D)))
	# plt.ylim()
	# plt.xlim([0,half_n_fft])
	# plt.show()
	# plt.pause(100)

	
	
	# note the abs
	# -------------------- CFAR detection ---------------------------
	# rank = 2*half_train - 1 
	# cfar_scale = 1 # additional scaling factor
	# cfar_up, upth = os_cfar(half_train, half_guard, rank, SOS, abs(FFT_U), cfar_scale)
	# cfar_dn, dnth = os_cfar(half_train, half_guard, rank, SOS, abs(FFT_D), cfar_scale)

	# cfar_up, upth = soca_cfar(half_train, half_guard, SOS, abs(FFT_U))
	# cfar_dn, dnth = soca_cfar(half_train, half_guard, SOS, abs(FFT_D))

	# cfar_up, upth = soca_cfar_edge(half_train, half_guard, SOS, abs(FFT_U))
	# cfar_dn, dnth = soca_cfar_edge(half_train, half_guard, SOS, abs(FFT_D))

	# CFAR Square law detector
	cfar_up, upth = ca_cfar_edge(half_train, half_guard, SOS, \
				np.square(np.real(FFT_U))+np.square(np.imag(FFT_U)), half_n_fft)
	cfar_dn, dnth = ca_cfar_edge(half_train, half_guard, SOS, \
				np.square(np.real(FFT_D))+np.square(np.imag(FFT_D)), half_n_fft)

# rank = half_train*2*3/4

	# np.log(upth, out=upth)
	# np.log(dnth, out=dnth)
	# np.log(abs(FFT_U), out=FFT_U)
	# np.log(abs(FFT_D), out=FFT_D)

	# upth = 20*np.log(upth)
	# dnth = 20*np.log(dnth)
	# FFT_U = 20*np.log(abs(FFT_U))
	# FFT_D = 20*np.log(abs(FFT_D))
	# cfar_up = 20*np.log(abs(cfar_res_up))
	# cfar_dn = 20*np.log(abs(cfar_res_dn))
	
	fbu = np.zeros(nbins)
	fbd = np.zeros(nbins)

	rg_array = np.zeros(nbins)
	# fd_array = np.zeros(nbins)
	sp_array = np.zeros(nbins)
	ratio = np.ones(nbins)*4 # above the unsafe time
	# sp_array_corrected = np.zeros(nbins)
	# beat_arr = np.zeros(nbins)

	# safety_inv = 0
	safety = 0
	index_end = 0
	beat_index = 0
	slope = 2.4e11
	c = 299792458
	lmda = 0.0125
	# ********************* beat extraction for multiple targets **************************
	for bin in range(nbins):
		# find beat frequency in bin of down chirp
		bin_slice_d = cfar_dn[bin*bin_width:(bin+1)*bin_width]

		# extract peak of beat frequency and intra-bin index
		magd = np.amax(bin_slice_d)
		idx_d = np.argmax(bin_slice_d)

		# np.amax(bin_slice_d, axis=0, out=magd)
		# np.argmax(bin_slice_d, axis=0, out=idx_d)
		
		# if there is a non-zero maximum
		if magd != 0:

			# index of beat frequency is bin index plus intra-bin index
			beat_index = bin*bin_width + idx_d

			# store down-chirp beat frequency
			fbd[bin] = fneg[beat_index]

			# handling edge case at the beginning of the sequence
			if (beat_index > scan_width):
				# set beat scan window width
				index_end = beat_index - scan_width
				# get up chirp spectrum window
				bin_slice_u = cfar_up[index_end:beat_index]

			# if too close to the start edge, scan from DC to index
			else:
				index_end = 0
				bin_slice_u = cfar_up[0:scan_width]
				# print(bin_slice_u)

				
			# Get magnitude and intra-bin index of beat frequency
			magu = np.amax(bin_slice_u)
			idx_u = np.argmax(bin_slice_u)

			# np.amax(bin_slice_u, axis=0, out=magu)
			# np.argmax(bin_slice_u, axis=0, out=idx_u)

			# if detection is made and target not static
			if (magu != 0) and (idx_u != idx_d):
				fbu[bin] = fpos[index_end + idx_u - 1]

			
				# if target moving towards radar
				if (fbu[bin] < fbd[bin]):
				# if (fbu[bin] > 0 and fbd[bin] > 0):

					# NOTE: div by 4: first division by 2 is for beat freq, 
					# second is for dop to vel - reducing the number of divisions

					half_fd = (-fbu[bin] + fbd[bin])*calib/4 
					
					# NOTE: fmin = 400 Hz corresponds to 9 km/h
					# fmin = 667 Hz corresponds to 15 km/h
					# fmax = 3125 Hz corresponds to 70 km/h
					# speeds are limited to these values on main roads
					# these are divided by two due to the optimisation above
					# fmin = 21 km/h corresponds to 933 Hz -> use 467 below
					# fmin = 1333.33 Hz for vmin = 30 km/h -> use 667 Hz below 
					if (1563>half_fd>667): 
						# fd_array[bin] = half_fd/2
						
						# if less than max expected and filter clutter doppler
						# if ((abs(half_fd/2) < fd_max) and (half_fd/2 > 400)):
						# convert Doppler to speed. half_fd is twice the Doppler therefore
						# divide by 2
						# sp_array[bin] = half_fd*lmda/2
						# Note that fbd is now positive
						rg_array[bin] = c*(fbu[bin] + fbd[bin])/(4*slope)*calib

						# to account for angle offset on left radar. 
						# for right radar, set angOffsetMinRange = 100
						if rg_array[bin] > angOffsetMinRange:
							sp_array[bin] = half_fd*lmda/(np.cos(angOffset - np.arcsin(road_width/rg_array[bin])))
						
						# Else ignore/dont correct for left and calculate as normal for right
						else:
							# sp_array[bin] = half_fd*lmda/(np.cos(np.arcsin(road_width/rg_array[bin])))
							# disable for rhs
							sp_array[bin] = half_fd*lmda
						
						# debug high speed getting through - due to rhs ang correction
						# if sp_array[bin]*3.6 > 70.4:
						# 	print("Speed violation when half_fd = ", str(half_fd), ", range: ", str(rg_array[bin]), ", speed: ", sp_array[bin])

						# ************* Angle correction *******************
						# Theta in radians
						# theta = np.arcsin(road_width/rg_array[bin])*correction_factor

						# # real_v = half_fd*lmda/(8*np.cos(theta))
						# sp_array[bin] = half_fd*lmda/(2*np.cos(theta))
					
	# print(Pfa)
	# ********************* Safety Algorithm ***********************************
	np.divide(rg_array,sp_array, ratio, where=sp_array>0)
	# t_safe = 3
	if (np.any(ratio<3.6)):
		# 1 indicates sweep contained target at unsafe distance
		# UPDATE: put the ratio/time into array to scale how
		# safe the turn is
		safety = min(ratio)
		# print("Unsafe Turn: ", safety)
		# for colour map:
		# safety_inv = 3-min(ratio)
		
	# log scale for display purposes
	return cfar_up, cfar_dn, upth, dnth, FFT_U, FFT_D, beat_index, index_end, rg_array, sp_array, safety
	# return rg_array, sp_array, safety
	# return cfar_res_up, cfar_res_dn, 20*np.log10(upth), 20*np.log10(dnth),\
	#      20*np.log10(abs(FFT_U), 10),  20*np.log10(abs(FFT_D))


# def range_speed_safety(i_data, q_data, windowCoeffs, n_fft, num_nul, half_train, 
# half_guard, rank, nbins, bin_width, f_ax, SOS, calib, scan_width, angOffsetMinRange, angOffset):
	
# 	# DC cancellation
# 	max_voltage = 3.3
# 	ADC_bits = 12
# 	ADC_intervals = 2**ADC_bits
	
# 	i_u = np.subtract(np.multiply(i_data[  0:200], max_voltage/ADC_intervals), np.mean(np.multiply(i_data[  0:200], max_voltage/ADC_intervals)))
# 	i_d = np.subtract(np.multiply(i_data[200:400], max_voltage/ADC_intervals), np.mean(np.multiply(i_data[200:400], max_voltage/ADC_intervals)))
# 	q_u = np.subtract(np.multiply(q_data[  0:200], max_voltage/ADC_intervals), np.mean(np.multiply(q_data[  0:200], max_voltage/ADC_intervals)))
# 	q_d = np.subtract(np.multiply(q_data[200:400], max_voltage/ADC_intervals), np.mean(np.multiply(q_data[200:400], max_voltage/ADC_intervals)))
	
# 	iq_u = np.multiply(i_u + 1j*q_u, windowCoeffs)
# 	iq_d = np.multiply(i_d + 1j*q_d, windowCoeffs)

# 	# Apply window function
# 	# iq_u = np.multiply(iq_u, windowCoeffs)
# 	# iq_d = np.multiply(iq_d, windowCoeffs)

# 	# 512-point FFT
# 	FFT_U = fft(iq_u, n_fft)
# 	FFT_D = fft(iq_d, n_fft)

# 	# Halve FFTs
# 	half_n_fft = int(n_fft/2)
# 	FFT_U = FFT_U[0:half_n_fft]
# 	FFT_D = FFT_D[half_n_fft: ]

# 	# Null feedthrough
# 	# FFT_U[0:num_nul-1] = 0
# 	# FFT_D[len(FFT_D)-num_nul:] = 0
# 	# print(len(FFT_U))
# 	FFT_D = np.flip(FFT_D)
	
# 	# -------------------- CFAR detection ---------------------------
# 	# cfar_scale = 1 # additional scaling factor
# 	# cfar_up, _ = os_cfar(half_train, half_guard, rank, SOS, abs(FFT_U), cfar_scale)
# 	# cfar_dn, _ = os_cfar(half_train, half_guard, rank, SOS, abs(FFT_D), cfar_scale)
	
# 	# cfar_up, _ = soca_cfar(half_train, half_guard, SOS, abs(FFT_U))
# 	# cfar_dn, _ = soca_cfar(half_train, half_guard, SOS, abs(FFT_D))

	
# 	# cfar_up, _ = soca_cfar_edge(half_train, half_guard, SOS, abs(FFT_U))
# 	# cfar_dn, _ = soca_cfar_edge(half_train, half_guard, SOS, abs(FFT_D))
# 		# CFAR Square law detector
# 	# cfar_up, upth = soca_cfar_edge(half_train, half_guard, SOS, \
# 	# 			np.square(np.real(FFT_U))+np.square(np.imag(FFT_U)))
# 	# cfar_dn, dnth = soca_cfar_edge(half_train, half_guard, SOS, \
# 	# 			np.square(np.real(FFT_D))+np.square(np.imag(FFT_D)))
# 	rank = round(half_train*2*3/4)
# 	cfar_up, upth = os_cfar_edge(half_train, half_guard, SOS, \
# 				np.square(np.real(FFT_U))+np.square(np.imag(FFT_U)), rank)
# 	cfar_dn, dnth = os_cfar_edge(half_train, half_guard, SOS, \
# 				np.square(np.real(FFT_D))+np.square(np.imag(FFT_D)), rank)
	

# 	# cfar_up, _ = soca_cfar_far_edge(half_train, half_guard, SOS, abs(FFT_U))
# 	# cfar_dn, _ = soca_cfar_far_edge(half_train, half_guard, SOS, abs(FFT_D))


# 	fbu = np.zeros(nbins)
# 	fbd = np.zeros(nbins)

# 	rg_array = np.zeros(nbins)
# 	sp_array = np.zeros(nbins)
# 	ratio = np.full(nbins, 5.0)
# 	# ratio = np.zeros(nbins)
# 	sp_array_corr = np.zeros(nbins)

# 	# safety_inv = 0
# 	safety = 0
# 	index_end = 0
# 	beat_index = 0
# 	slope = 2.4e11
# 	c = 299792458
# 	lmda = 0.0125
# 	road_width = 2
# 	correction_factor = 3
# 	fdMax = 2.6667e3 # for max speed = 60km/h
# 	fdMax = 2.6667e3 # for max speed = 60km/h
# 	fdMin = 444
# 	# magu = 0
# 	# idx_u = 0
# 	# magd = 0
# 	# idx_d = 0

# 	# ********************* beat extraction for multiple targets **************************
# 	for bin in range(nbins):
# 		# find beat frequency in bin of down chirp
# 		bin_slice_d = cfar_dn[bin*bin_width:(bin+1)*bin_width]

# 		# extract peak of beat frequency and intra-bin index
# 		magd = np.amax(bin_slice_d)
# 		idx_d = np.argmax(bin_slice_d)
# 		# np.amax(bin_slice_d, axis=0, out=magd)
# 		# np.argmax(bin_slice_d, axis=0, out=idx_d)
		
# 		# if there is a non-zero maximum
# 		if magd != 0:

# 			# index of beat frequency is bin index plus intra-bin index
# 			beat_index = bin*bin_width + idx_d

# 			# store down-chirp beat frequency
# 			fbd[bin] = f_ax[beat_index]

# 			# handling edge case at the beginning of the sequence
# 			if (beat_index > scan_width):
# 				# set beat scan window width
# 				index_end = beat_index - scan_width
# 				# get up chirp spectrum window
# 				bin_slice_u = cfar_up[index_end:beat_index]

# 			# if too close to the start edge, scan from DC to index
# 			else:
# 				index_end = 0
# 				bin_slice_u = cfar_up[0:scan_width]
				
# 			# Get magnitude and intra-bin index of beat frequency
# 			magu = np.amax(bin_slice_u)
# 			idx_u = np.argmax(bin_slice_u)
# 			# np.amax(bin_slice_u, axis=0, out=magu)
# 			# np.argmax(bin_slice_u, axis=0, out=idx_u)


# 			# if detection is made and target not static
# 			if (magu != 0) and (idx_u != idx_d):
# 				fbu[bin] = f_ax[index_end + idx_u - 1]

			
# 				# if both not DC
# 				if (fbu[bin] < fbd[bin]):
# 					half_fd = (-fbu[bin] + fbd[bin])*calib/4 # divide by 4 instead of 2 to eliminate further divisions
# 					# fd_array[bin] = half_fd/2
					
# 					# if less than max expected and filter clutter doppler
# 					# if ((abs(half_fd/2) < fd_max) and (half_fd/2 > 400)):
# 					# if (fdMin < half_fd < fdMax):
# 					if (fdMin < half_fd): # NOTE: max limited by scan width
# 						# convert Doppler to speed. half_fd is twice the Doppler therefore
# 						# divide by 2
# 						# sp_array[bin] = half_fd*lmda
# 						# Note that fbd is now positive
# 						rg_array[bin] = c*(fbu[bin] + fbd[bin])/(4*slope)*calib

# 						# to account for angle offset on left radar. for right radar, set angOffsetMinRange = 100
# 						if rg_array[bin] > angOffsetMinRange:
# 							sp_array[bin] = half_fd*lmda/(np.cos(angOffset - np.arcsin(road_width/rg_array[bin])))
						
# 						# Else ignore/dont correct for left and calculate as normal for right
# 						else:
# 							sp_array[bin] = half_fd*lmda/(np.cos(np.arcsin(road_width/rg_array[bin])))
	


# 						# ************* Angle correction *******************
# 						# Theta in radians
# 						# theta = np.arcsin(road_width/rg_array[bin])*correction_factor

# 						# real_v = half_fd*lmda/(8*np.cos(theta))
						
						
# 	# print(Pfa)
# 	# ********************* Safety Algorithm ***********************************
# 	# where arg: Elsewhere, the out array will retain its original value
# 	np.divide(rg_array,sp_array, ratio, where=sp_array!=0)
# 	# t_safe = 3
# 	if (np.any(ratio<3)):
# 		# 1 indicates sweep contained target at unsafe distance
# 		# UPDATE: put the ratio/time into array to scale how
# 		# safe the turn is
# 	# print(ratio)
# 		safety = min(ratio)


# 	# return rg_array, sp_array, safety, fbu, fbd, sp_array_corr, cfar_up, cfar_dn
# 	return rg_array, sp_array, safety