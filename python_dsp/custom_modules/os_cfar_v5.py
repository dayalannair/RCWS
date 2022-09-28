import numpy as np
import math as mt
# train = training cells on either side
# guard = guard cells on either side
# rank = 
# data = data set
# Pfa = probability of false alarm
# This version ignores all cells with insufficient self.lead/self.lag cells
# for training

class OS_CFAR:
    # Pre calculate self.SOS for a given Pfa
    def __init__(self, ns, half_train, half_guard, rank, SOS):
        self.ns = ns
        self.half_train = half_train
        self.half_guard = half_guard
        self.lead = half_train + half_guard
        self.lag = ns - self.lead
        self.N = 2*half_train - 2*half_guard
        self.k = rank
        self.SOS = SOS
        self.result = np.zeros(ns)
        self.th = np.zeros(ns)

    def os_cfar(self, data):
    
        for cutidx in range(self.ns): #cutidx = index of cell under test

            # ******************* Set up training cells *****************
            # If no LHS training cells, take cells right of RHS
            if (cutidx<=self.half_guard):
                rhs_train = data[cutidx+self.half_guard:cutidx+self.lead]
                lhs_train = data[cutidx+self.lead:cutidx+self.lead+self.half_train]

            # IF some LHS cells, use these and take remainder from RHS
            elif (cutidx<self.lead):
                # RHS train cells set as normal
                rhs_train = data[cutidx+self.half_guard:cutidx+self.lead]
                # add all cells from pos 0 up to guard to train set
                lhs_train = data[0:cutidx-self.half_guard]
                # space = number of lhs train cells still to be filled
                lhs_fill = self.half_train-len(lhs_train)
                # add cells to the right of rhs train cells to the lhs side
                lhs_train = np.append(lhs_train, data[cutidx+self.lead:cutidx+self.lead+lhs_fill])
                # lhs_train.append(data[cutidx+self.lead:cutidx+self.lead+lhs_fill])

            # IF enough train cells on either side
            elif (self.lead<cutidx<self.lag):
                # print("In range. Cutidx = ", cutidx)
                lhs_train = data[cutidx-self.lead:cutidx-self.half_guard]
                rhs_train = data[cutidx+self.half_guard:cutidx+self.lead]
                # print("Size lhs = ", np.size(lhs_train))
                # print("Size rhs = ", np.size(rhs_train))

            # IF too few cells on the right, take some from left of LHS    
            elif (cutidx >= (self.ns-self.lead)):
                # LHS as normal 
                lhs_train = data[cutidx-self.lead:cutidx-self.half_guard]

                rhs_train = data[cutidx+self.half_guard:]
                # print(len(rhs_train))
                rhs_fill = self.half_train-len(rhs_train)
                rhs_train = np.append(rhs_train, data[cutidx-self.lead-rhs_fill:cutidx-self.lead])
                # rhs_train.append(data[cutidx-self.lead-rhs_fill:cutidx-self.lead])
                # print(len(lhs_train))
                # print(len(rhs_train))

            elif (cutidx >= (self.ns-self.half_guard)):
                lhs_train = data[cutidx-self.lead:cutidx-self.half_guard]
                rhs_train = data[cutidx-self.lead-self.half_train:cutidx-self.lead]


            training_cells = np.concatenate((lhs_train,rhs_train))
            # print(np.size(training_cells))
            # print(k)
            # ******************** Perform OS CFAR ***********************
            cut = data[cutidx]
            # print("Train cells number = ", np.size(training_cells))
            training_cells.sort()
            ZOS = training_cells[k]
            # print(ZOS)
            TOS = self.SOS*ZOS
            # print('TOS =', TOS)
            self.th[cutidx] = TOS
            # print('TOS =', self.th[cutidx])
            if cut > TOS:
                # index implies frequency. return magnitude for use in
                # determining max value
                self.result[cutidx] = cut
            # ************************************************************
        return self.result, self.th




def config_os_cfar(self.ns, self.half_train, self.half_guard, rank, self.SOS):
    
    self.lead = self.half_train + self.half_guard # max num cells considered on either side of cut
    self.lag = self.ns - self.lead
    # k = rank
    N = 2*self.half_train - 2*self.half_guard
    
    # Try these methods
    # k = round(3*N/4)
    k = rank

    # print(data)
    # print("N (num training) = ", N)
    # print("train half = ", self.half_train)
    # print("Guard half = ", self.half_guard)
    # print("k = ", k)
    # print("self.ns = ", self.ns)
    # Pfa_numer = k*mt.factorial(N)* mt.factorial(k-1)*mt.factorial(self.SOS+N-k)
    # Pfa_denom = (mt.factorial(k)*mt.factorial(N-k))*mt.factorial(self.SOS+N)
    # Pfa = Pfa_numer/Pfa_denom
    Pfa = k*mt.factorial(N)/(mt.factorial(k)*mt.factorial(N-k)) \
        * mt.factorial(k-1)*mt.factorial(self.SOS+N-k)/mt.factorial(self.SOS+N)

    print(Pfa)








