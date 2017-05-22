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


# xmin xsize ymin ysize zmin zsize 
PARMAX=(161 144)
PARMIN=(89 72)
ATLAS='DET0001101'
NUM='3'
ATLAS_IMAGE="../data/${ATLAS}.nii.gz"
ATLAS_LABEL="../seg/${ATLAS}_seg.nii.gz"
OUTPUT_PREFIX="./data/d${NUM}"
doroi

PARMAX=(151 161)
PARMIN=(76 69)
ATLAS='DET0001401'
ATLAS_IMAGE="../data/${ATLAS}.nii.gz"
ATLAS_LABEL="../seg/${ATLAS}_seg.nii.gz"
NUM='4'
OUTPUT_PREFIX="./data/d${NUM}"
doroi

PARMAX=(173 145)
PARMIN=(81 31)
ATLAS='DET0001701'
NUM='5'
ATLAS_IMAGE="../data/${ATLAS}.nii.gz"
ATLAS_LABEL="../seg/${ATLAS}_seg.nii.gz"
OUTPUT_PREFIX="./data/d${NUM}"
doroi


PARMAX=(174 165)
PARMIN=(86 58)
ATLAS='DET0002501'
NUM='6'
ATLAS_IMAGE="../data/${ATLAS}.nii.gz"
ATLAS_LABEL="../seg/${ATLAS}_seg.nii.gz"
OUTPUT_PREFIX="./data/d${NUM}"
doroi



exit 0
