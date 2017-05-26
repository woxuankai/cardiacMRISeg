#!/usr/bin/python3

import os
import sys

import numpy as np
import nibabel as nib
import matplotlib.pyplot as plt

if len(sys.argv) != 3:
    print('usage: '+sys.argv[0]+' input.nii.gz output.nii.gz')
    sys.exit()

img=nib.load(sys.argv[1])
data=img.get_data()
affine=img.get_affine()
shape=img.get_shape()

for x in range(0, shape[0]):
    for y in range(0, shape[1]):
        if x%5 == 3 or y%5 == 3:
            data[x,y]=1
        else:
            data[x,y]=0

new_img=nib.Nifti1Image(data,affine)
#new_img.header=img.get_header()
nib.save(new_img,sys.argv[2])
