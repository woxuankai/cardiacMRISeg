#!/usr/bin/python3
# -*- coding: utf-8 -*-

import sys
import csv
import numpy as np
import matplotlib.pyplot as plt

if __name__ == '__main__':
    if(len(sys.argv) < 2):
        print('usage: '+sys.argv[0]+' file.csv')
        sys.exit(1)
    with open(sys.argv[1], newline='') as f:
        reader = csv.reader(f)
        csvhead = next(reader)
        target=[]
        atlas_img=[]
        dice=[]
        MI=[]
        CC=[]
        MSQ=[]
        for oneline in reader:
            dice.append(float(oneline[csvhead.index('dice')]))
            MI.append(float(oneline[csvhead.index('MI')]))
            CC.append(float(oneline[csvhead.index('CC')]))
            MSQ.append(float(oneline[csvhead.index('MSQ')]))
            target.append(oneline[csvhead.index('target')])
            atlas_img.append(oneline[csvhead.index('atlas_img')])
        dice=np.array(dice)
        MI=np.array(MI)
        CC=np.array(CC)
        MSQ=np.array(MSQ)
    if(target.count(target[0]) != len(target)):
        print('targets not all the same')
        sys.exit(1)
    plt.figure(1)
    plt.plot(MI,dice,'ro')
    plt.title('target: '+target[1])
    plt.xlabel('Mutual Information')
    plt.ylabel('dice')
    
    plt.figure(2)
    plt.plot(CC,dice,'ro')
    plt.title('target: '+target[1])
    plt.xlabel('Cross Correlation')
    plt.ylabel('dice')
   
    plt.figure(3)
    plt.plot(MSQ,dice,'ro')
    plt.title('target: '+target[1])
    plt.xlabel('Mean Square Difference')
    plt.ylabel('dice')
    plt.show()

