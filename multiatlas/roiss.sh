#!/bin/bash

mkdir -p ./data
function getslicenum(){
	fsl5.0-fslinfo "$1" | fgrep -w dim3 | tr -s ' ' | cut -d' ' -f2
	return 0
}
function getvolumenum(){
	fsl5.0-fslinfo "$1" | fgrep -w dim4 | tr -s ' ' | cut -d' ' -f2
	return 0
}
ROI='fsl5.0-fslroi'



function doroi(){
NUM_SLICE="$(getslicenum ${ATLAS_IMAGE})"
NUM_VOLUME="$(getvolumenum ${ATLAS_IMAGE})"
for ((i = 0; i < $NUM_VOLUME; i++))
do
	for ((j = 0; j < $NUM_SLICE; j++))
	do
		$ROI "${ATLAS_IMAGE}" \
			"${OUTPUT_PREFIX}_v${i}_s${j}.nii.gz" \
			$PAR ${j} 1 ${i} 1
		$ROI "${ATLAS_LABEL}" \
			"${OUTPUT_PREFIX}_v${i}_s${j}_seg.nii.gz" \
			$PAR ${j} 1 ${i} 1
	done
done
}


# xmin xsize ymin ysize zmin zsize 
PAR='100 81  61 101'
# x180 y161
ATLAS_IMAGE='../data/DET0002701.nii.gz'
ATLAS_LABEL='../gt/DET0002701_seg.nii.gz'
OUTPUT_PREFIX='./data/d0'
doroi


PAR='91 75  68 82'
# x165 y149
ATLAS_IMAGE='../data/DET0009301.nii.gz'
ATLAS_LABEL='../gt/DET0009301_seg.nii.gz'
OUTPUT_PREFIX='./data/d1'
doroi


PAR='93 78  75 76'
# y170 y150
ATLAS_IMAGE='../data/DET0016101.nii.gz'
ATLAS_LABEL='../gt/DET0016101_seg.nii.gz'
OUTPUT_PREFIX='./data/d2'
doroi

exit 0
