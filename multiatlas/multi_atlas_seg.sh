#!/bin/bash

DOREG='./doreg.sh'
FSLHD='fsl5.0-fslhd'
FSLMERGE='fsl5.0-fslmerge'
PARALLEL='parallel'
ANTSREG='antsRegistration'
ANTAPPLY='antsApplyTransforms'
MEASURESIM='MeasureImageSimilarity'
IMAGEMATH='ImageMath'

# check software dependency
for APP in $ANTSREG $ANTSAPPLY $PARALLEL $IMAGEMATH \
	$DOREG $MEASURESIM $FSLHD $FSLMERGE
do
	which "$APP" >/dev/null || \
		{ echo "cannot execute $APP" >&2; exit 1; }
done

function usage(){
	cat >&2 <<ENDOFUSAGE
usage:
multi_atlas_seg.sh
	-t <target> -p <target_label_prediction>
	[-n <best N labels used for label fusion>, default 4]
	[-v verbose, default 0]
	[-j parallel job number, default 4]
	[-f fusion method, majoriyvote(default) or staple]
	[-s skip registration if possible, default 0]
	[-d <output file> calculate dice]
	[-h (help)]
	-i <atlas_image1> -l <atlas_label1>
	-i <atlas_image2> -l <atlas_label2>
	...
	-i <atlas_imageN> -l <atlas_labelN>
ENDOFUSAGE
}


# mandatory arguments
ATLAS_IMAGES=() # i
ATLAS_LABELS=() # l
TARGET='' # t
PREDICTION='' # p

# optional arguments
PARALLELJOBS='3' # j
VERBOSE=0 # v
FUSENUM='4' # n
FUSIONMETHOD='majorityvote' # f
SKIPREG='1' # s
DICEFILE='' # d


# parse arguments
while getopts 't:p:i:l:j:n:v:f:s:d:h' OPT
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
			VERBOSE="$OPTARG"
			;;
		n) # best n labels
			FUSENUM="$OPTARG"
			;;
		f) # label fusion method
			FUSIONMETHOD="$OPTARG"
			;;
		s) # skip registration if possible
			SKIPREG="$OPTARG"
			;;
		d) # show dice
			DICEPATH="$OPTDICE"
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

# mandatory arguments
# ATLAS_IMAGES=() 
# ATLAS_LABELS=()
test "${#ATLAS_IMAGES[@]}" -eq "${#ATLAS_LABELS[@]}" || \
	{ echo "altas images and labels don't match" >&2; exit 1; }
test "${#ATLAS_IMAGES[@]}" -ge 2 || \
	{ echo "altas image and label not enough" >&2; exit 1; }
# TARGET=''
test -r "$TARGET" || \
	{ echo "target (-t) not set or not accessable" >&2; usage; exit 1; }
# PREDICTION='' 
test -n "$PREDICTION" || \
	{ echo "label prediction (-p) not set" >&2; usage; exit 1; }

# optional arguments
test "$ARALLELJOBS" -gt 0 || \
	{ echo "parallel jobs (-j) should > 0" >&2; exit 1; }
test "$VERBOSE" -ge 0 || \
	{ echo "verbose (-j) option should >= 0" >&2; exit 1; }
test "$FUSENUM" -ge 2 && test "$FUSENUM" -le "${#ATLAS_LABELS[@]}" || \
	{ echo "fusenum (-n) should >=2 and <= ${#ATLASL_LABELS[@]}" >&2; 
		exit 1; }
test ${FUSIONMETHOD} = "majorityvote" || test ${FUSIONMETHOD} = "staple" || \
	{ echo "invalid -f ${FUSIONMETHOD}" >&2; exit 1; }
test ${SKIPREG} -ge 0 || \
	{ echo "${SKIPREG} should >= 0" >&2; exit 1; }
# DICEFILE
test "${VERBOSE}" -ge 1 && \
	echo ###############################

# care only if set
test "$FUSENUM" -gt 0 && test "$FUSENUM" -le "${#ATLAS_IMAGES[@]}" || \
	{ echo "label number for fusion -n ${FUSENUM} \
shoud > 0 and <= number of atlases ( ${#ATLAS_IMAGES[@]} )"; exit 1 ; }
test "$PARALLELJOBS" -gt 0 || \
	{ echo "invalid job number $PARALLELJOBS"; exit 1; }


# get dimensionality
DIM="$( ${FSLHD} ${TARGET} | fgrep -w 'dim0' | tr -s ' ' | cut -d' ' -f2 )"
test "${DIM}" -ge 2 && test "${DIM}" -le 3 || \
	{ echo "dimensionality not available" >&2 ; exit 1; }

# do registration
BASEPATH="$(dirname ${PREDICTION})/$(basename ${PREDICTION} | cut -d. -f1)"
PARALLELJOB_DOREG=''
PARALLELJOB_APPLYT=''
WARPED_IMAGES=()
WARPED_LABELS=()
for (( i = 0; i < ${#ATLAS_IMAGES[@]}; i++ ))
do
	WARPED_IMAGE="${BASEPATH}_warpedimage_${i}.nii.gz"
	WARPED_LABEL="${BASEPATH}_warpedlabel_${i}.nii.gz"
	TRANSFORM="${BASEPATH}_transform_${i}_"
	rm -f "${WARPPED_IMAGE}" "${WARPED_LABEL}" "${TRANSFORM}"* || \
		{ echo "unable to delete some existing file(s)"; exit 1; }
	WARPED_IMAGES[${#WARPED_IMAGES[@]}]="$WARPED_IMAGE"
	WARPED_LABELS[${#WARPED_LABELS[@]}]="$WARPED_LABEL"
	PARALLELJOB_DOREG="${PARALLELJOB_DOREG} \
		$DOREG \
		-d '${DIM}' \
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

# label fusion
# choose best n labels
# compute and sort similarity
SIMILARITIES=()
SIMILARITY_GATE=''
PARALLELJOB_SORT=''
# compute
for (( i = 0; i < ${#ATLAS_IMAGES[@]}; i++ ))
do
	# 1 for cross correlation
	SIMILARITY=$( MeasureImageSimilarity ${DIM} 1 \
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
	LABEL4D="${BASEPATH}_4D.nii.gz"
	fsl5.0-fslmerge -t ${LABEL4D} ${LABELS_CHOSEN[@]} || \
		{ echo "failed to merge to 4D label"; exit 1; }
	seg_LabFusion -in "${LABEL4D}" -STAPLE -out "${PREDICTION}" || \
		{ echo "failed to do staple"; exit 1; }
	}
staple

exit 0

