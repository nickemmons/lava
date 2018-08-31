import numpy as np
from scipy import special as sp
from scipy import misc as ms
from math import pi as PI
from math import isnan

# estimates
NP = np.array([10**i for i in range(1,7)]) # 10:1M
NR = np.array([10**i for i in range(1,7)]) # 10:1M

# hyperparameters
A = np.array([10**i for i in range(1,5)]) # 10-10k
X = np.array([2**i for i in [2**j for j in range(2,8)]]) # 4:256:2^i

# matrix elements
Q = lambda N: ms.factorial(N-1) / ms.factorial(N) # helper
alpha = lambda _np: 1.0/_np
beta = lambda _a, _np, _x: _a*Q(float(int(_np/_x)))/_x
gamma = lambda _x: (1.0/_x) - 1.0
delta = lambda _a, _np, _nr, _x: ((1.0 - 1.0/_x)**_np) \
                                * Q(_nr) \
                                * (((PI**2.0)/6.0) - sp.polygamma(1, _a) - 0.75)
epsilon = lambda _a, _np, _nr, _x: (_a/_nr) * (((1.0-(1.0/_x))**_np) - 1.0)

# 2x3
mat = lambda _a, _np, _nr, _x: np.array([ \
    [alpha(_np), beta(_a, _np, _x), gamma(_x)], \
    [delta(_a, _np, _nr, _x), epsilon(_a, _np, _nr, _x), 0] \
    ])

#2x2
mat2 = lambda _a, _np, _nr, _x: np.array([ \
    [alpha(_np), beta(_a, _np, _x) + gamma(_x)], \
    [delta(_a, _np, _nr, _x), epsilon(_a, _np, _nr, _x)] \
    ])

Yval = np.array([[1],[1]])

def solve(M, Y):
    '''
    solve 2x3 case of: MX = Y
    '''
    MT = np.transpose(M)
    almost = np.linalg.inv(M.dot(MT))
    gettingThere = MT.dot(almost)
    return gettingThere.dot(Y)

# A: 1000
# NP: 1000
# NR: 100000
# X: 256
# ans:
#  [[30.77441776]
#  [ 1.01274183]]
# Demonstration of Optimal 2x2 Parameters in practice
# ans2 = np.array([[30.77441776], [1.01274183]])
# inputs2 = (1000, 1000, 100000, 256)
# print('EV_2 of preders, randers', mat2(*inputs2).dot(ans2))
# quit()

possible = 0
for a in A:
    for nnp in NP:
        for nr in NR:
            for x in X:
                # use try-except in case of singular matrices
                try:
                    # ans = solve(mat(a, nnp, nr, x), Yval) # 2x3
                    ans = np.linalg.inv(mat2(a, nnp, nr, x)).dot(Yval) # 2x2
                    if not isnan(ans[0][0]) and not isnan(ans[1][0]) \
                        and ans[0][0] > 0 and ans[1][0] > 0 \
                        and a <= 1000 \
                        :
                        print('\n------')
                        print('A:', a)
                        print('NP:', nnp)
                        print('NR:', nr)
                        print('X:', x)
                        print('ans:\n', ans)
                        possible += 1
                except:
                    pass
print('\n------\n\nPOSSIBLE: ', possible, '\n')

# Best Hyper/Parameter Combination: (courtesy of 2x2 case)
# ------
# A: 100
# NP: 100
# NR: 100
# X: 65536
# ans:
#  [[ 113.20453437] -> 857.302519111325 -> 857
#  [   0.13204736]] -> 1.0 -> 1
# => Expected winning from preder and rander = 0.13204736 wei
# ------

