#!/bin/bash
function usage(){
	cat >&2 << ENDOFUSAGE
usage:
doreg.sh
	-f <fixed image (target)> -l <label of moving image (atlas seg)>
	-m <moving image (atlas lable)> -t <transform base path>
	-s <warped label (target seg)> -w <warped image>
	-d <dimensionality>
	[-s <skip registration if possible, default 0>]
	[-h (show help)]

AUTHOR: Kai Xuan <woxuankai@gmail.com>
ENDOFUSAGE
}

SKIP='0'
# parse arguments
while getopts 'f:l:m:t:s:w:d:k:h' OPT
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
		t) # transform basepath
			TRANS="$OPTARG"
			;;
		s) # warped label (segment for target/fixed)
			WSEG="$OPTARG"
			;;
		w) # warped moving image
			WMOVING="$OPTARG"
			;;
		d) # dimensionality
			DIM="$OPTARG"
			;;
		k) # skip if possible
			SKIP="$OPTARG"
			;;
		h) # show help
			usage
			exit 0
			;;
		\?) # getopts error
			usage
			exit 1
			;;
	esac
done

# verify arguments
test -r "$FIXED" || \
	{ echo "unable to access $FIXED" >&2; usage;  exit 1; }

test -r "$MOVING" || \
	{ echo "unable to access $MOVING" >&2; usage; exit 1; }

test -r "$SEG" || \
	{ echo "unable to access $SEG" >&2; usage; exit 1; }

test -n "$WSEG" || \
	{ echo "missing -s option" >&2; usage; exit 1; }
mkdir -p $(dirname "$WSEG") || \
	{ echo "unable to mkdir for $WSEG" >&2; exit 1; } 

test -n "$TRANS" || \
	{ echo "missing -b option" >&2; usage; exit 1; }
mkdir -p $(dirname "$TRANS") || \
	{ echo "unable to mkdir for transformation" >&2; exit 1; }

test -n "$WMOVING" || \
	{ echo "missing -w option" >&2; usage; exit 1; }
mkdir -p $(dirname "$WMOVING") || \
	{ echo "unable to mkdir for warped image" >&2; exit 1; }


test "$DIM" -eq 2 || test "$DIM" -eq 3 || \
	{ echo "-d should be either 2 or 3" >&2; exit 1; }



# registration
if test "${SKIP}" -ge 1
then
	for OFILE in "${FIXED}" "${MOVING}" "${SEG}"
	do
		for NFILE in "${WSEG}" "${WMOVING}" \
			#"${TRANS}1BSpline.txt" "${TRANS}0GenericAffine.mat"
		do
			test -r "${NFILE}" && \
				test -r "${OFILE}" && \
				test "${NFILE}" -nt "${OFILE}" || \
				SKIP=0
		done
	done
fi
# if every test passed, exit
test "${SKIP}" -ge 1 && exit 0

antsRegistration \
	--verbose 0 --dimensionality ${DIM} --float 0 \
	--output "[${TRANS},${WMOVING}]" \
	--interpolation Linear --use-histogram-matching 0 \
	--winsorize-image-intensities '[0.005,0.995]' \
	--initial-moving-transform "[$FIXED,$MOVING,1]" \
	--transform 'Affine[0.1]' \
	--metric "MI[$FIXED,$MOVING,1,24]" \
	--convergence [1000x500x250x0,1e-6,10] \
	--shrink-factors 8x4x2x1 \
	--smoothing-sigmas 3x2x1x0vox \
	--transform BSpline[0.1,200] \
	--metric "CC[$FIXED,$MOVING,1,4]" \
	--convergence [800x400x200x0,1e-6,10] \
	--shrink-factors 8x4x2x1 \
	--smoothing-sigmas 3x2x1x0vox \
	|| { echo "Error!! failed to do registration" >&2; exit 1;}

# apply transform
antsApplyTransforms \
	-d ${DIM} --float 0 \
	-i ${SEG} -r ${FIXED} -o ${WSEG} -n NearestNeighbor\
	-t ${TRANS}1BSpline.txt \
	-t ${TRANS}0GenericAffine.mat \
	|| { echo "Error!! fialed to apply transform" >&2; exit 1;}

exit 0;

