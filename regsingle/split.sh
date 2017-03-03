#!/bin/bash
ROI='fsl5.0-fslroi'


# xmin xsize ymin ysize zmin zsize
PAR="85 101	62 102	0 -1"
# (85,62)->(185,163)
VOLUMEMAX=19
for (( i = 0; i <= ${VOLUMEMAX}; i++ ))
do
	$ROI ../data/DET0002701.nii.gz ./data/d0_v${i}.nii.gz $PAR ${i} 1
	$ROI ../gt/DET0002701_seg.nii.gz ./data/d0_v${i}_seg.nii.gz $PAR ${i} 1
done
PAR='82 95	64 87	0 -1'
# (82,64)->(176,150)
VOLUMEMAX=19
for (( i = 0; i <= ${VOLUMEMAX}; i++ ))
do
	$ROI ../data/DET0009301.nii.gz ./data/d1_v${i}.nii.gz $PAR ${i} 1
	$ROI ../gt/DET0009301_seg.nii.gz ./data/d1_v${i}_seg.nii.gz $PAR ${i} 1
done
PAR='89 88	73 81	0 -1'
# (89,73)->(176,153)
VOLUMEMAX=24
for (( i = 0; i <= ${VOLUMEMAX}; i++ ))
do
	$ROI ../data/DET0016101.nii.gz ./data/d2_v${i}.nii.gz $PAR ${i} 1
	$ROI ../gt/DET0016101_seg.nii.gz ./data/d2_v${i}_seg.nii.gz $PAR ${i} 1
done
