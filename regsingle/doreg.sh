#!/bin/bash

#ATLAS='d2'  #imaged segmented
#TARGET='d1' #image to be segmented

if test $# -ge 2
then
	TARGET="$1"
	ATLAS="$2"
	echo "target image is $TARGET"
	echo "altas is $ATLAS"
else
	echo "usage: $0 <TargetName> <AtlasName> [options]"
	echo "options:"
	echo "-v: view result"
	echo "-d: show dice value"
	echo "-m: metric"
	echo "-t: transform"
	echo "target and atlas are expected in ./data/ folder"
	exit 1
fi

#rm ./output/*
mkdir -p ./output

FIXED="./data/${TARGET}.nii.gz"
MOVING="./data/${ATLAS}.nii.gz"

test -f "$FIXED" || { echo "cannot find $FIXED" ; exit 1; }
test -f "$MOVING" || { echo "cannot find $MOVING" ; exit 1; }
DIM=$(fsl5.0-fslhd "${FIXED}" | fgrep -w dim0 | tr -s ' ' | cut -d' ' -f2)
test "$DIM" -eq 2 || test "$DIM" -eq 3 || \
	{ echo "dimentionality should be either 2 or 3"; exit 1; }


shift;shift
OPTVIEW=false
OPTDICE=false
METRIC="CC[$FIXED,$MOVING,1,4]"
# METRIC="MI[$FIXED,$MOVING,1,32]"
TRANSFORM="BSpline[0.1,200]"
while getopts "vdm:t:" OPT
do
	case $OPT in
		v)
			OPTVIEW=true
			;;
		d)
			OPTDICE=true
			;;
		m)
			# METRIC=$OPTARG
			;;
		t)
			TRANSFORM=$OPTARG
			;;
		\?)
			;;

	esac
done



SEGMENT="./data/${ATLAS}_seg.nii.gz"
SEGW="./output/${TARGET}_seg_prediction_from_${ATLAS}.nii.gz"
TRANS="./output/Transform_${ATLAS}_to_${TARGET}"
ATLASW="./output/Warped${ATLAS}_for_${TARGET}.nii.gz"
antsRegistration \
	--verbose 0 --dimensionality ${DIM} --float 0 \
	--output "[${TRANS},${ATLASW}]" \
	--interpolation Linear --use-histogram-matching 0 \
	--winsorize-image-intensities '[0.005,0.995]' \
	--initial-moving-transform "[$FIXED,$MOVING,1]" \
	--transform 'Rigid[0.1]' \
	--metric "${METRIC}" \
	--convergence [1000x500x250x0,1e-6,10] \
	--shrink-factors 8x4x2x1 \
	--smoothing-sigmas 3x2x1x0vox \
	--transform 'Affine[0.1]' \
	--metric "${METRIC}" \
	--convergence [1000x500x250x0,1e-6,10] \
	--shrink-factors 8x4x2x1 \
	--smoothing-sigmas 3x2x1x0vox \
        --transform ${TRANSFORM} \
	--metric "${METRIC}" \
	--convergence [800x400x200x0,1e-6,10] \
	--shrink-factors 8x4x2x1 \
	--smoothing-sigmas 3x2x1x0vox

antsApplyTransforms \
	-d ${DIM} --float 0 \
	-i ${SEGMENT} -r ${FIXED} -o ${SEGW} -n NearestNeighbor\
	-t ${TRANS}1BSpline.txt \
	-t ${TRANS}0GenericAffine.mat

GOLDEN="./data/${TARGET}_seg.nii.gz"
DICE="./output/dice_${TARGET}_prediction_from_${ATLAS}.txt"
DOVIEW="fslview -m single ${FIXED} ${ATLASW} -t 0.1 ${GOLDEN} -l Red -t 0.5 ${SEGW} -l Blue -t 0.5"
DODICE="ImageMath ${DIM} $DICE DiceAndMinDistSum "$GOLDEN" "$SEGW""

test $OPTDICE && {
eval "$DODICE"
echo " "
echo -e "${DICE}\n" $(cat "$DICE"); }

test $OPTVIEW && eval "$DOVIEW" &
exit 0

