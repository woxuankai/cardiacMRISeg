#!/usr/bin/python3

import numpy as np
import matplotlib.pyplot as plt
import sys

result_d0=np.array([
0.816355,
0.798618,
0.865579,
0.822685,
0.848179,
0.829071,
0.825366,
0.839375,
0.787625,
0.813208,
0.857356,
0.824654,
0.876723,
0.816367,
0.86262,
0.807463,
0.876763,
0.820513,
0.843598,
0.739881
])

result_d1=np.array([
0.818785,
0.749478,
0.804903,
0.762532,
0.846612,
0.827305,
0.835964,
0.809387,
0.830943,
0.812915,
0.838674,
0.834491,
0.823735,
0.822754,
0.802279,
0.833816,
0.824697,
0.693902,
0.841371,
0.75237
])

fig,ax=plt.subplots()
bplot=ax.boxplot(np.array([result_d0,result_d1]).T)
ax.yaxis.grid(True)
ax.set_xlabel('target')
ax.set_ylabel('Dice')
ax.set_title('Multi Atlas Registration Result Summary')
ax.set_xticklabels(['DET0002701','DET0009301'])

fig,ax=plt.subplots()
tplot=ax.plot(result_d0,'ro',result_d1,'b*')
ax.yaxis.grid(True)
ax.set_xlabel('volume')
ax.set_ylabel('Dice')
ax.set_title('Multi Atlas Registration Result')
ax.legend(['DET0002701','DET0009301'])

plt.show()
