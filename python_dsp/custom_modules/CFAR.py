import numpy as np
import math as mt

# ====================================================================================
# CFAR LIBRARY
# Author : Dayalan Nair
# Date   : December 2022
# Description : Set of  CFAR algorithms including OS and SOCA CFAR. Advanced edge case
# handling included.
# ------------------------------------------------------------------------------------
# PARAMETERS
#
# train = training cells on either side
# guard = guard cells on either side
# rank = 
# data = data set
# Pfa = probability of false alarm
# This version ignores all cells with insufficient lead/lag cells
# for training
# ====================================================================================


# NOTE: rhs edge case not handled since target SNR is too weak at these distances.
# Detection is unlikely.

def soca_cfar(half_train, half_guard, SOS, data):

    ns = len(data) # number of samples
    result = np.zeros(ns)
    th = np.zeros(ns)
    lead = half_train + half_guard # max num cells considered on either side of cut
    lag = ns - lead
    for cutidx in range(lead,lag): #cutidx = index of cell under test
        
        # extract training sets
        lhs_train = data[cutidx-lead:cutidx-half_guard]
        rhs_train = data[cutidx+half_guard:cutidx+lead]

        cut = data[cutidx]
        ZOS = min(np.average(lhs_train),np.average(rhs_train))
        TOS = SOS*ZOS
        th[cutidx] = TOS
        # print('TOS =', th[cutidx])
        if cut > TOS:
            # index implies frequency. return magnitude for use in
            # determining max value
            result[cutidx] = cut

    return result, th


def soca_cfar_old(half_train, half_guard, SOS, data):

    ns = len(data) # number of samples
    result = np.zeros(ns)
    th = np.zeros(ns)
    lead = half_train + half_guard # max num cells considered on either side of cut
    lag = ns - lead
    for cutidx in range(ns): #cutidx = index of cell under test
        
        # If no LHS training cells, take cells right of RHS
        if (cutidx<=half_guard):
            rhs_train = data[cutidx+half_guard:cutidx+lead]
            lhs_train = data[cutidx+lead:cutidx+lead+half_train]
            cut = data[cutidx]
            ZOS = min(np.average(lhs_train),np.average(rhs_train))
            TOS = SOS*ZOS
            # print(TOS)
            th[cutidx] = TOS
            if cut > TOS:
                result[cutidx] = cut
        
         # IF some LHS cells, use these and take remainder from RHS
        elif (cutidx<lead):
            # RHS train cells set as normal
            rhs_train = data[cutidx+half_guard:cutidx+lead]
            # add all cells from pos 0 up to guard to train set
            lhs_train = data[0:cutidx-half_guard]
            # space = number of lhs train cells still to be filled
            lhs_fill = half_train-len(lhs_train)
            # add cells to the right of rhs train cells to the lhs side
            lhs_train = np.append(lhs_train, data[cutidx+lead:cutidx+lead+lhs_fill])
            # lhs_train.append(data[cutidx+lead:cutidx+lead+lhs_fill])
            cut = data[cutidx]
            ZOS = min(np.average(lhs_train),np.average(rhs_train))
            TOS = SOS*ZOS
            th[cutidx] = TOS
            if cut > TOS:
                result[cutidx] = cut

        if (lead<cutidx<lag):
            lhs_train = data[cutidx-lead:cutidx-half_guard]
            rhs_train = data[cutidx+half_guard:cutidx+lead]

            cut = data[cutidx]
            ZOS = min(np.average(lhs_train),np.average(rhs_train))
            TOS = SOS*ZOS
            th[cutidx] = TOS
            # print('TOS =', th[cutidx])
            if cut > TOS:
                # index implies frequency. return magnitude for use in
                # determining max value
                result[cutidx] = cut

    return result, th

def os_cfar(half_train, half_guard, rank, SOS, data, cfar_scale):

    ns = len(data) # number of samples
    result = np.zeros(ns)
    th = np.zeros(ns)
    lead = half_train + half_guard # max num cells considered on either side of cut
    lag = ns - lead
    N = 2*half_train - 2*half_guard
    k = rank
    for cutidx in range(ns): #cutidx = index of cell under test
        # IF some LHS cells, use these and take remainder from RHS
        
        if (lead<cutidx<lag):
            lhs_train = data[cutidx-lead:cutidx-half_guard]
            rhs_train = data[cutidx+half_guard:cutidx+lead]
            training_cells = np.concatenate((lhs_train,rhs_train))
            # ******************** Perform OS CFAR ***********************
            cut = data[cutidx]
            training_cells.sort()
            ZOS = training_cells[k]
            TOS = SOS*ZOS
            th[cutidx] = TOS
            # print('TOS =', th[cutidx])
            if cut > TOS*cfar_scale:
                # index implies frequency. return magnitude for use in
                # determining max value
                result[cutidx] = cut
            # ************************************************************
    return result, th

def soca_cfar_edge(half_train, half_guard, SOS, data):

    ns = len(data) # number of samples
    result = np.zeros(ns)
    th = np.zeros(ns)
    lead = half_train + half_guard # max num cells considered on either side of cut
    lag = ns - lead
    N = 2*half_train - 2*half_guard
    

    for cutidx in range(ns): #cutidx = index of cell under test

        # ******************* Set up training cells *****************
        # If no LHS training cells, take cells right of RHS
        if (cutidx<=half_guard):
            rhs_train = data[cutidx+half_guard:cutidx+lead]
            lhs_train = data[cutidx+lead:cutidx+lead+half_train]

        # IF some LHS cells, use these and take remainder from RHS
        elif (cutidx<lead):
            # RHS train cells set as normal
            rhs_train = data[cutidx+half_guard:cutidx+lead]
            # add all cells from pos 0 up to guard to train set
            lhs_train = data[0:cutidx-half_guard]
            # space = number of lhs train cells still to be filled
            lhs_fill = half_train-len(lhs_train)
            # add cells to the right of rhs train cells to the lhs side
            lhs_train = np.append(lhs_train, data[cutidx+lead:cutidx+lead+lhs_fill])
            # lhs_train.append(data[cutidx+lead:cutidx+lead+lhs_fill])

        # IF enough train cells on either side
        elif (lead<cutidx<lag):
            # print("In range. Cutidx = ", cutidx)
            lhs_train = data[cutidx-lead:cutidx-half_guard]
            rhs_train = data[cutidx+half_guard:cutidx+lead]
            # print("Size lhs = ", np.size(lhs_train))
            # print("Size rhs = ", np.size(rhs_train))

        # IF too few cells on the right, take some from left of LHS    
        elif (cutidx >= (ns-lead)):
            # LHS as normal 
            lhs_train = data[cutidx-lead:cutidx-half_guard]

            rhs_train = data[cutidx+half_guard:]
            # print(len(rhs_train))
            rhs_fill = half_train-len(rhs_train)
            rhs_train = np.append(rhs_train, data[cutidx-lead-rhs_fill:cutidx-lead])
            # rhs_train.append(data[cutidx-lead-rhs_fill:cutidx-lead])
            # print(len(lhs_train))
            # print(len(rhs_train))

        elif (cutidx >= (ns-half_guard)):
            lhs_train = data[cutidx-lead:cutidx-half_guard]
            rhs_train = data[cutidx-lead-half_train:cutidx-lead]


        cut = data[cutidx]
        # print("Train cells number = ", np.size(training_cells))
        # print(ZOS)
        ZOS = min(np.average(lhs_train),np.average(rhs_train))
        TOS = SOS*ZOS
        # print('TOS =', TOS)
        th[cutidx] = TOS
        # print('TOS =', th[cutidx])
        if cut > TOS:
            # index implies frequency. return magnitude for use in
            # determining max value
            result[cutidx] = cut
        # ************************************************************
    return result, th

def soca_cfar_far_edge(half_train, half_guard, SOS, data):

    ns = len(data) # number of samples
    result = np.zeros(ns)
    th = np.zeros(ns)
    lead = half_train + half_guard # max num cells considered on either side of cut
    lag = ns - lead
    N = 2*half_train - 2*half_guard
    

    for cutidx in range(ns): #cutidx = index of cell under test

        # # If no LHS training cells, take cells right of RHS
        # if (cutidx<=half_guard):
        #     rhs_train = data[cutidx+half_guard:cutidx+lead]
        #     lhs_train = data[cutidx+lead:cutidx+lead+half_train]

        # IF some LHS cells, use these and take remainder from RHS
        # if (cutidx<lead):
        #     # RHS train cells set as normal
        #     rhs_train = data[cutidx+half_guard:cutidx+lead]
        #     # add all cells from pos 0 up to guard to train set
        #     lhs_train = data[0:cutidx-half_guard]
        #     # space = number of lhs train cells still to be filled
        #     lhs_fill = half_train-len(lhs_train)
        #     # add cells to the right of rhs train cells to the lhs side
        #     lhs_train = np.append(lhs_train, data[cutidx+lead:cutidx+lead+lhs_fill])
        #     # lhs_train.append(data[cutidx+lead:cutidx+lead+lhs_fill])
        #     cut = data[cutidx]
        #     ZOS = min(np.average(lhs_train),np.average(rhs_train))
        #     TOS = SOS*ZOS
        #     th[cutidx] = TOS
        #     if cut > TOS:
        #         result[cutidx] = cut

        # IF enough train cells on either side
        if (lead<cutidx<lag):
            lhs_train = data[cutidx-lead:cutidx-half_guard]
            rhs_train = data[cutidx+half_guard:cutidx+lead]
            cut = data[cutidx]
            ZOS = min(np.average(lhs_train),np.average(rhs_train))
            TOS = SOS*ZOS
            th[cutidx] = TOS
            if cut > TOS:

                result[cutidx] = cut

        # IF too few cells on the right, take some from left of LHS    
        elif (cutidx >= (ns-lead)):
            # LHS as normal 
            lhs_train = data[cutidx-lead:cutidx-half_guard]

            rhs_train = data[cutidx+half_guard:]

            rhs_fill = half_train-len(rhs_train)
            rhs_train = np.append(rhs_train, data[cutidx-lead-rhs_fill:cutidx-lead])
            cut = data[cutidx]

            ZOS = min(np.average(lhs_train),np.average(rhs_train))
            TOS = SOS*ZOS
            th[cutidx] = TOS
            if cut > TOS:
                result[cutidx] = cut

        elif (cutidx >= (ns-half_guard)):
            lhs_train = data[cutidx-lead:cutidx-half_guard]
            rhs_train = data[cutidx-lead-half_train:cutidx-lead]
            cut = data[cutidx]
            # print("Train cells number = ", np.size(training_cells))
            # print(ZOS)
            ZOS = min(np.average(lhs_train),np.average(rhs_train))
            TOS = SOS*ZOS
            # print('TOS =', TOS)
            th[cutidx] = TOS
            # print('TOS =', th[cutidx])
            if cut > TOS:
                # index implies frequency. return magnitude for use in
                # determining max value
                result[cutidx] = cut
            
        # NOTE: The below did not produce correct results,
        # so the proc was added to each case
        # no further proc if not in one of the cases
        # else:
        #     return result, th

    return result, th

def os_cfar_edge(half_train, half_guard, SOS, data, rank):

    ns = len(data) # number of samples
    result = np.zeros(ns)
    th = np.zeros(ns)
    lead = half_train + half_guard # max num cells considered on either side of cut
    lag = ns - lead
    # k = rank
    N = 2*half_train - 2*half_guard
    
    # Try these methods
    # k = round(3*N/4)
    k = rank

    # print(data)
    # print("N (num training) = ", N)
    # print("train half = ", half_train)
    # print("Guard half = ", half_guard)
    # print("k = ", k)
    # print("ns = ", ns)
    # Pfa_numer = k*mt.factorial(N)* mt.factorial(k-1)*mt.factorial(SOS+N-k)
    # Pfa_denom = (mt.factorial(k)*mt.factorial(N-k))*mt.factorial(SOS+N)
    # Pfa = Pfa_numer/Pfa_denom
    # Pfa = k*mt.factorial(N)/(mt.factorial(k)*mt.factorial(N-k)) \
    #     * mt.factorial(k-1)*mt.factorial(SOS+N-k)/mt.factorial(SOS+N)

    # print(Pfa)

    for cutidx in range(ns): #cutidx = index of cell under test

        # ******************* Set up training cells *****************
        # If no LHS training cells, take cells right of RHS
        if (cutidx<=half_guard):
            rhs_train = data[cutidx+half_guard:cutidx+lead]
            lhs_train = data[cutidx+lead:cutidx+lead+half_train]

        # IF some LHS cells, use these and take remainder from RHS
        elif (cutidx<lead):
            # RHS train cells set as normal
            rhs_train = data[cutidx+half_guard:cutidx+lead]
            # add all cells from pos 0 up to guard to train set
            lhs_train = data[0:cutidx-half_guard]
            # space = number of lhs train cells still to be filled
            lhs_fill = half_train-len(lhs_train)
            # add cells to the right of rhs train cells to the lhs side
            lhs_train = np.append(lhs_train, data[cutidx+lead:cutidx+lead+lhs_fill])
            # lhs_train.append(data[cutidx+lead:cutidx+lead+lhs_fill])

        # IF enough train cells on either side
        elif (lead<cutidx<lag):
            # print("In range. Cutidx = ", cutidx)
            lhs_train = data[cutidx-lead:cutidx-half_guard]
            rhs_train = data[cutidx+half_guard:cutidx+lead]
            # print("Size lhs = ", np.size(lhs_train))
            # print("Size rhs = ", np.size(rhs_train))

        # IF too few cells on the right, take some from left of LHS    
        elif (cutidx >= (ns-lead)):
            # LHS as normal 
            lhs_train = data[cutidx-lead:cutidx-half_guard]

            rhs_train = data[cutidx+half_guard:]
            # print(len(rhs_train))
            rhs_fill = half_train-len(rhs_train)
            rhs_train = np.append(rhs_train, data[cutidx-lead-rhs_fill:cutidx-lead])
            # rhs_train.append(data[cutidx-lead-rhs_fill:cutidx-lead])
            # print(len(lhs_train))
            # print(len(rhs_train))

        elif (cutidx >= (ns-half_guard)):
            lhs_train = data[cutidx-lead:cutidx-half_guard]
            rhs_train = data[cutidx-lead-half_train:cutidx-lead]


        training_cells = np.concatenate((lhs_train,rhs_train))
        # print(np.size(training_cells))
        # print(k)
        # ******************** Perform OS CFAR ***********************
        cut = data[cutidx]
        # print("Train cells number = ", np.size(training_cells))
        training_cells.sort()
        ZOS = training_cells[k]
        # print(ZOS)
        TOS = SOS*ZOS
        # print('TOS =', TOS)
        th[cutidx] = TOS
        # print('TOS =', th[cutidx])
        if cut > TOS:
            # index implies frequency. return magnitude for use in
            # determining max value
            result[cutidx] = cut
        # ************************************************************
    return result, th





