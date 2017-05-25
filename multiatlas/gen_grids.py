#!/usr/bin/python3

import os
import sys

import numpy as np
import nibabel as nib
import matplotlib.pyplot as plt

if len(os.argv) != 3:
    print('usage: '+os.argv[0]+'input.nii.gz output.nii.gz')

