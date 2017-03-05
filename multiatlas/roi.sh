#!/bin/bash
ROI='fsl5.0-fslroi'
# xmin xsize ymin ysize zmin zsize 
PAR='100 81     61 101  8 1'
VOLMAX='19'
# x180 y161
for ((i = 0; i <= $VOLMAX; i++))
do
$ROI ../data/DET0002701.nii.gz ./data/d0_v${i}.nii.gz $PAR ${i} 1
$ROI ../gt/DET0002701_seg.nii.gz ./data/d0_v${i}_seg.nii.gz $PAR ${i} 1
done


PAR='91 75      68 82   5 1'
VOLMAX='19'
# x165 y149
for ((i = 0; i <= $VOLMAX; i++))
do
$ROI ../data/DET0009301.nii.gz ./data/d1_v${i}.nii.gz $PAR ${i} 1
$ROI ../gt/DET0009301_seg.nii.gz ./data/d1_v${i}_seg.nii.gz $PAR ${i} 1
done


PAR='93 78      75 76   8 1'
# y170 y150
VOLMAX='24'
for ((i = 0; i <= $VOLMAX; i++))
do
$ROI ../data/DET0016101.nii.gz ./data/d2_v${i}.nii.gz $PAR ${i} 1
$ROI ../gt/DET0016101_seg.nii.gz ./data/d2_v${i}_seg.nii.gz $PAR ${i} 1
done
exit 0
