#!/bin/bash

./multi_atlas_seg.sh \
	-t ../reg2d/data/d0.nii.gz \
	-p ./output/predict_seg.nii.gz \
	-v \
	-j 4 \
	-i ../reg2d/data/d1.nii.gz -l ../reg2d/data/d1_seg.nii.gz \
	-i ../reg2d/data/d2.nii.gz -l ../reg2d/data/d2_seg.nii.gz

