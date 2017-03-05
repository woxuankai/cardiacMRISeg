#!/bin/bash

function usage(){
	cat <<ENDOFUSAGE
usage:
multi_atlas_seg.sh
	-t <target> -p <target_label_prediction>
	-n <best N labels used for label fusion>
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
FUSENUM=''
DIM='2'


# check software dependency
which antsRegistration >/dev/null || \
	echo "cannot find antsRegistration"
which antsApplyTransforms >/dev/null || \
	echo "cannot find antsApplyTransforms"
which parallel >/dev/null || parallel --version | fgrep -q "GNU parallel" || \
	echo "cannot find GNU parallel"
test -x "$DOREG" || \
	{ echo "$DOREG doesn't exits or is not executable"; exit 1; }
which MeasureImageSimilarity >/dev/null || \
	echo "cannot find MeasureImageSimilarty"



# parse arguments
while getopts 't:p:i:l:j:n:vh' OPT
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
		v) # verbose ####
			VERBOSE=true
			;;
		n) # best n labels
			FUSENUM="$OPTARG"
			;;
		f) # label fusion method ####
			;;
		s) # skip registration if possible  ####
			;;
		d) # show dice ####
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
test "$FUSENUM" -gt 0 && test "$FUSENUM" -le "${#ATLAS_IMAGES[@]}" || \
	{ echo "label number for fusion -n ${FUSENUM} \
shoud > 0 and <= number of atlases ( ${#ATLAS_IMAGES[@]} )"; exit 1 ; }
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
	TRANSFORM="${BASENAME}_transform_${i}_"
	rm -f "${WARPPED_IMAGE}" "${WARPED_LABEL}" "${TRANSFORM}"* || \
		{ echo "unable to delete some existing file(s)"; exit 1; }
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
$VERBOSE && \
	{ echo "IFNO: doing registration"; SHOWBAR='--bar'; } || \
	SHOWBAR=''
# ignore non-empty line
# (which will also be considered as a command in parallel)
echo -e "$PARALLELJOB_DOREG" | \
	grep -v '^$' | \
	parallel -j $PARALLELJOBS $SHOWBAR
# check output which may imply if the registration succeeds.
for (( i = 0; i < ${#WARPED_IMAGES[@]}; i++ ))
do
	test -r "${WARPED_IMAGES[${i}]}" && \
		test -r "${WARPED_LABELS[${i}]}" || \
		{ echo "registraion ${ATLAS_IMAGES[$i]} -> ${TARGET} failed"; \
			exit 1; }
done


#doreg.sh -f <fixed image (target)> -l <label of moving image (atlas seg)>
#-m <moving image (atlas lable)> -t <transform basename>
#-s <warped label (target seg)> -w <warped image>

# label fusion
# choose best n labels
# compute and sort similarity
SIMILARITIES=()
SIMILARITY_GATE=''
PARALLELJOB_SORT=''
# compute
for (( i = 0; i < ${#ATLAS_IMAGES[@]}; i++ ))
do
	SIMILARITY=$( MeasureImageSimilarity 2 1 \
		${TARGET} ${WARPED_IMAGES[$i]} | \
		fgrep '=> CC' | rev | cut -d' ' -f1 | rev )
	SIMILARITIES[${#SIMILARITIES[@]}]="${SIMILARITY}"
done
# sort
SIMILARITY_GATE=$( echo ${SIMILARITIES[@]} | \
	tr " " "\n" | sort -gr | cut -d$'\n' -f"${FUSENUM}" )

$VERBOSE && echo "selected atlases:"
LABELS_CHOSEN=() # sometimes number of chosen labels may be larger than FUSENUM
for (( i = 0; i < ${#ATLAS_IMAGES[@]}; i++ ))
do
	test $(echo "${SIMILARITIES[${i}]} >= ${SIMILARITY_GATE}" | bc) \
	       	-eq 1 && \
		LABELS_CHOSEN[${#LABELS_CHOSEN[@]}]="${WARPED_LABELS[$i]}" && \
		$VERBOSE && echo "${ATLAS_IMAGES[$i]}"
done

# fuse
function majorityvote(){
	ImageMath "${DIM}" "${PREDICTION}" \
		MajorityVoting ${LABELS_CHOSEN[@]} || \
		{ echo "failed to do majority voting"; exit 1; }
	}
function staple(){
	LABEL4D="${BASENAME}_4D.nii.gz"
	fsl5.0-fslmerge -t ${LABEL4D} ${LABELS_CHOSEN[@]} || \
		{ echo "failed to merge to 4D label"; exit 1; }
	seg_LabFusion -in "${LABEL4D}" -STAPLE -out "${PREDICTION}" || \
		{ echo "failed to do staple"; exit 1; }
	}
staple

exit 0

