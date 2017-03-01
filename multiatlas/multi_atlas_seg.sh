#!/bin/bash

function usage(){
	cat <<ENDOFUSAGE
usage:
multi_atlas_seg.sh
	-t <target> -p <target_label_prediction>
	[-v (verbose, no arugment)]
	[-j <parallel job number>]
	[-h (help, no arugment)]
	-i <atlas_image1> -l <atlas_label1>
	-i <atlas_image2> -l <atlas_label2>
	...
	-i <atlas_imageN> -l <atlas_labelN>
ENDOFUSAGE
}

ATLAS_IMAGES=()
ATLAS_LABELS=()
TARGET=''
PREDICTION=''
PARALLELJOBS='3'
DOREG='./doreg.sh'
VERBOSE=false

# check software dependency
which antsRegistration >/dev/null || \
	echo "cannot find antsRegistration"
which antsApplyTransforms >/dev/null || \
	echo "cannot find antsApplyTransforms"
which parallel >/dev/null || parallel --version | fgrep -q "GNU parallel" || \
	echo "cannot find GNU parallel"
test -x "$DOREG" || \
	{ echo "$DOREG doesn't exits or is not executable"; exit 1; }

# parse arguments
while getopts 't:p:i:l:j:vh' OPT
do
	case $OPT in
		t) # target
			TARGET="$OPTARG"
			;;
		p) # prediction output
			PREDICTION="$OPTARG"
			;;
		i) # image
			ATLAS_IMAGES[${#ATLAS_IMAGES[@]}]="$OPTARG"
			;;
		l) # label
			ATLAS_LABELS[${#ATLAS_LABELS[@]}]="$OPTARG"
			;;
		j) # parallel jobs
			PARALLELJOBS="$OPTARG"
			;;
		v) # verbose
			VERBOSE=true
			;;
		h) # help
			usage
			exit 0;
			;;
		\?) # unknown
			usage
			exit 1;
			;;
	esac
done


# verify argument parameters
test -r "$TARGET" || \
	{ echo "cannot find target image (-t) $TARGET"; usage; exit 1; }
test -n "$PREDICTION" || \
	{ echo "prediction segmentation (-p) not set"; usage; exit 1; }  && \
	mkdir -p $( dirname $PREDICTION ) && \
	touch "$PREDICTION" || \
	{ echo "permission denied creating $PREDICTION"; exit 1; }
test "${#ATLAS_IMAGES[@]}" -eq "${#ATLAS_LABELS[@]}" || \
	{ echo "altas images and labels don't match"; exit 1; }
test "${#ATLAS_IMAGES[@]}" -gt 0 || \
	{ echo "altas image and label not specified"; exit 1; }
for (( i = 0; i < ${#ATLAS_IMAGES[@]}; i++ ))
do
	test -r "${ATLAS_IMAGES[$i]}" || \
		{ echo "file $ATLAS_IMAGES[$i] unreadable or doesn't exist"; \
			usage; exit 1; }
	test -r "${ATLAS_LABELS[$i]}" || \
		{ echo "file $ATLAS_LABELS[$i] unreadable or doesn't exist"; \
			usage; exit 1; }
done
test "$PARALLELJOBS" -gt 0 || \
	{ echo "invalid job number $PARALLELJOBS"; exit 1; }

# do registration
BASENAME="$(dirname ${PREDICTION})/$(basename ${PREDICTION} | cut -d. -f1)"
PARALLELJOB_DOREG=''
PARALLELJOB_APPLYT=''
WARPED_IMAGES=()
WARPED_LABELS=()
for (( i = 0; i < ${#ATLAS_IMAGES[@]}; i++ ))
do
	WARPED_IMAGE="${BASENAME}_warpedimage_${i}.nii.gz"
	WARPED_LABEL="${BASENAME}_warpedlabel_${i}.nii.gz"
	TRANSFORM="${BASENAME}_transform_"
	WARPED_IMAGES[${#WARPED_IMAGES[@]}]="$WARPED_IMAGE"
	WARPED_LABELS[${#WARPED_LABELS[@]}]="$WARPED_LABEL"
	PARALLELJOB_DOREG="${PARALLELJOB_DOREG} \
		$DOREG \
		-f '${TARGET}' \
		-l '${ATLAS_LABELS[$i]}' \
		-m '${ATLAS_IMAGES[$i]}' \
		-t '${TRANSFORM}' \
		-s '${WARPED_LABEL}' \
		-w '${WARPED_IMAGE}' \
		\n"
done
test $VERBOSE && \
	{ echo "IFNO: doing registration"; SHOWBAR='--bar'; } || \
	SHOWBAR=''
echo -e "$PARALLELJOB_DOREG" | parallel -j $PARALLELJOBS $SHOWBAR

#doreg.sh -f <fixed image (target)> -l <label of moving image (atlas seg)>
#-m <moving image (atlas lable)> -t <transform basename>
#-s <warped label (target seg)> -w <warped image>

exit 0

