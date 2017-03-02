#!/bin/bash
FIXED='test/test0.nii.gz'
MOVING='train/train0.nii.gz'
OUTPUT='./output/affine'
OUTPUTW='./output/affineWarped.nii.gz'
OUTPUTIW='./output/affineInverseWarped.nii.gz'
METRIC="MI[$FIXED,$MOVING,1,32,Regular,0.25]"
CONVERGENCE='[1000x500x250x0,1e-6,10]'
antsRegistration \
	--verbose 1 --dimensionality 2 --float 0 \
	--output "[$OUTPUT,$OUTPUTW,$OUTPUTIW]" \
	--interpolation Linear --use-histogram-matching 0 \
	--winsorize-image-intensities '[0.005,0.995]' \
	--initial-moving-transform "[$FIXED,$MOVING,1]" \
	--transform 'Rigid[0.1]' \
	--metric "$METRIC" \
	--convergence "$CONVERGENCE" \
	--shrink-factors 8x4x2x1 \
	--smoothing-sigmas 3x2x1x0vox \
	--transform 'Affine[0.1]' \
	--metric "$METRIC" \
	--convergence "$CONVERGENCE" \
	--shrink-factors 8x4x2x1 \
	--smoothing-sigmas 3x2x1x0vox
