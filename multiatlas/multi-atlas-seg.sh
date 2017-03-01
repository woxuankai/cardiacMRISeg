#!/bin/bash

function usage(){
	cat <<ENDOFUSAGE
usage:
multi_atlas_seg.sh
	-t <target> -p <target_label_prediction>
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

# parse arguments
while getopts 't:p:i:l:' OPT
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
		\?) # unknown
			usage
			exit 1;
			;;
	esac
done

# verify argument parameters
test -r "$TARGET" || { echo "cannot find target image (-t) $TARGET"; exit 1; }
test -n "$PREDICTION" || \
	{ echo "prediction segmentation (-p) not set"; exit 1; }  && \
	mkdir -p $( dirname $PREDICTION ) && \
	touch "$PREDICTION" || \
	{ echo "permission denied creating $PREDICTION"; exit 1; }
test "${ATLAS_IMAGES[@]}" -eq "${ATLAS_LABELS[@]}" || \
	{ echo "altas images and labels don't match"; exit 1; }
for (( i = 0; i < ${#ATLAS_IMAGES[@]}; i++ ))
do
	test -r "$ATLAS_IMAGES[$i]" || \
		{ echo "file $ATLAS_IMAGES[$i] unreadable or doesn't exit"; \
			exit 1; }
	test -r "$ATLAS_LABELS[$i]" || \
		{ echo "file $ATLAS_LABELS[$i] unreadable or doesn't exit"; \
			exit 1; }
done

# do registration
for (( i = 0; i < ${#ATLAS_IMAGES[@]}; i++ ))


#doreg.sh -f <fixed image (target)> -l <label of moving image (atlas seg)>
#-m <moving image (atlas lable)> -t <transform basename>
#-s <warped label (target seg)> -w <warped image>

exit 0

