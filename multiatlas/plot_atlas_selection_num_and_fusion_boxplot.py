#!/usr/bin/python3
# -*- coding: utf-8 -*-

import sys
import csv
import numpy as np
import matplotlib.pyplot as plt

if __name__ == '__main__':
    if(len(sys.argv) < 2):
        print("reading from stdin...")
        f=sys.stdin.readlines()
    else:
        f=open(sys.argv[1], newline='')
    reader = csv.reader(f)
    csvhead = next(reader)
    target=[]
    num=[]
    MV=[]
    STAPLE=[]
    for oneline in reader:
        MV.append(float(oneline[csvhead.index('MV')]))
        STAPLE.append(float(oneline[csvhead.index('STAPLE')]))
        target.append(oneline[csvhead.index('target')])
        num.append(oneline[csvhead.index('num')])
    if(type(f) != type([])): # if f is a description
        f.close()
    MV=np.array(MV)
    STAPLE=np.array(STAPLE)
    num=np.array(num)
    if(target.count(target[0]) != len(target)):
        print('targets not all the same')
        sys.exit(1)
    plt.figure(1)
    plt.plot(num,MV,'*-r', label='majority vote')
    plt.plot(num,STAPLE,'+-b', label='STAPLE')
    plt.legend(loc='upper right')
    #plt.ylim([0.60,0.90])
    plt.title('target: '+target[1])
    plt.xlabel('number of atlases chosen for label fusion')
    plt.ylabel('dice')
    plt.show()

