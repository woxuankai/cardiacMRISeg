#!/bin/bash
function usage(){
	cat << ENDOFUSAGE
usage:
doreg.sh
	-f <fixed image (target)> -l <label of moving image (atlas seg)>
	-m <moving image (atlas lable)> -t <transform basename>
	-s <warped label (target seg)> -w <warped image>
ENDOFUSAGE
}


# parse arguments
while getopts 'f:l:m:t:s:w:' OPT
do
	case $OPT in
		f) # fixed image
			FIXED="$OPTARG"
			;;
		l) # label(segmentation) of movimg image
			SEG="$OPTARG"
			;;
		m) # moving image
			MOVING="$OPTARG"
			;;
		t) # transform basename
			TRANS="$OPTARG"
			;;
		s) # warped label (segment for target/fixed)
			WSEG="$OPTARG"
			;;
		w) # warped moving image
			WMOVING="$OPTARG"
			;;
		\?) # getopts error
			usage
			exit 1
			;;
	esac
done

# verify arguments
test -f $FIXED || \
	{echo "unable to find fixed image $FIXED"; usage;  exit 1; }
test -f $MOVING || \
	{echo "unable to find moving image $MOVING"; usage; exit 1; }
test -f $SEG || \
	{echo "unable to find atlas lable $SEG"; usage; exit 1; }
test -n $WSEG || \
	{echo "missing warped label filename (-t)"; usage; exit 1; }
test -n $TRANS || \
	{echo "missing transform filename (-s)"; usage; exit 1; }
test -n $WMOVING || \
	{echo "missing warped moving image filename (-w)"; usage; exit 1; }

# registration

antsRegistration \
	--verbose 0 --dimensionality 2 --float 0 \
	--output "[${TRANS},${WMOVING}]" \
	--interpolation Linear --use-histogram-matching 0 \
	--winsorize-image-intensities '[0.005,0.995]' \
	--initial-moving-transform "[$FIXED,$MOVING,1]" \
	--transform 'Rigid[0.1]' \
	--metric "MI[$FIXED,$MOVING,1,32,Regular,0.25]" \
	--convergence [1000x500x250x0,1e-6,10] \
	--shrink-factors 8x4x2x1 \
	--smoothing-sigmas 3x2x1x0vox \
	--transform 'Affine[0.1]' \
	--metric "MI[$FIXED,$MOVING,1,32,Regular,0.25]" \
	--convergence [1000x500x250x0,1e-6,10] \
	--shrink-factors 8x4x2x1 \
	--smoothing-sigmas 3x2x1x0vox \
	--transform BSpline[0.5,400] \
	--metric "MI[$FIXED,$MOVING,1,32]" \
	--convergence [800x400x200x0,1e-6,10] \
	--shrink-factors 8x4x2x1 \
	--smoothing-sigmas 3x2x1x0vox \
	|| {echo "Error!! failed to do registration"; exit 1;}

# apply transform
antsApplyTransforms \
	-d 2 --float 0 \
	-i ${SEG} -r ${FIXED} -o ${WSEG} -n Linear \
	-t ${TRANS}1BSpline.txt \
	-t ${TRANS}0GenericAffine.mat \
	|| {echo "Error!! fialed to apply transform"; exit 1;}

exit 0;

