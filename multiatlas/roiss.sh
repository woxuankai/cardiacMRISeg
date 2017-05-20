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
  PAR="${PARMIN[0]} $((${PARMAX[0]}-${PARMIN[0]}+1))"
  PAR="${PAR} ${PARMIN[1]} $((${PARMAX[1]}-${PARMIN[1]}+1))"
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
  cat << EOF > "${OUTPUT_PREFIX}.info"
NUM_SLICE=${NUM_SLICE}
NUM_VOLUME=${NUM_VOLUME}
EOF
done
}


# xmin xsize ymin ysize zmin zsize 
#PARMAX=(129 117)
#PARMIN=(58 33)
#ATLAS='DET000101.nii.gz'
#NUM='0'
#ATLAS_IMAGE="../data/${ATLAS}"
#ATLAS_LABEL="../seg/${ATLAS}"
#OUTPUT_PREFIX="./data/d${NUM}"
#doroi

#PAR='100 81  61 101'
PARMIN=(100 61)
PARMAX=(180 161)
ATLAS_IMAGE='../data/DET0002701.nii.gz'
ATLAS_LABEL='../seg/DET0002701_seg.nii.gz'
OUTPUT_PREFIX='./data/d0'
doroi


#PAR='91 75  68 82'
PARMIN=(91 68)
PARMAX=(165 149)
# x165 y149
ATLAS_IMAGE='../data/DET0009301.nii.gz'
ATLAS_LABEL='../seg/DET0009301_seg.nii.gz'
OUTPUT_PREFIX='./data/d1'
doroi


#PAR='93 78  75 76'
PARMIN=(93 75)
PARMAX=(170 150)
# y170 y150
ATLAS_IMAGE='../data/DET0016101.nii.gz'
ATLAS_LABEL='../seg/DET0016101_seg.nii.gz'
OUTPUT_PREFIX='./data/d2'
doroi

exit 0
