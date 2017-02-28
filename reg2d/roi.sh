#!/bin/bash
ROI='fsl5.0-fslroi'
# xmin xsize ymin ysize zmin zsize tmin tsize
PAR='100 81	61 101	8 1	0 1'
# x180 y161
$ROI ../data/DET0002701.nii.gz ./data/d0.nii.gz $PAR
$ROI ../gt/DET0002701_seg.nii.gz ./data/d0_seg.nii.gz $PAR
PAR='91 75	68 82	5 1	0 1'
# x165 y149
$ROI ../data/DET0009301.nii.gz ./data/d1.nii.gz $PAR
$ROI ../gt/DET0009301_seg.nii.gz ./data/d1_seg.nii.gz $PAR
PAR='93 78	75 76	8 1	0 1'
# y170 y150
$ROI ../data/DET0016101.nii.gz ./data/d2.nii.gz $PAR
$ROI ../gt/DET0016101_seg.nii.gz ./data/d2_seg.nii.gz $PAR
