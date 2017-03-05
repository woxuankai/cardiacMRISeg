#!/bin/bash

# usage: $0 [spec vol]

SPEC='d0'
VOL='v1'
test $# -ge 2 && { SPEC="$1"; VOL=$2; }

TARGET="${SPEC}_${VOL}"
PREDICTION="./output/${TARGET}_seg_prediction.nii.gz"
echo "target ${TARGET}"

ATLAS=$(ls ./data | fgrep -v ${SPEC} | fgrep -v seg)
ARG=''
for ONEATLAS in $ATLAS
do
	BASENAME=$(echo "$ONEATLAS" | cut -d'.' -f1)
	ARG="${ARG} \
-i ./data/${BASENAME}.nii.gz -l ./data/${BASENAME}_seg.nii.gz"
done

echo "altases argument ${ARG}"

./multi_atlas_seg.sh \
	-t "./data/${TARGET}.nii.gz" \
	-p "${PREDICTION}" \
	-v \
	-j 4 \
	-n 4 \
	${ARG}

LabelOverlapMeasures 2 "${PREDICTION}" "./data/${TARGET}_seg.nii.gz"
