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
	[-v verbose, default 0.
		1: show selected atlases, 2: less, 3: more, 4: debug]
	[-j parallel job number, default 4]
	[-f fusion method, majoriyvote(default) or staple]
	[-s skip if possible( according to file modification date), default 0]
	[-h (help)]
	-i <atlas_image1> -l <atlas_label1> -w <warped_image1> -a <warped_label1>
	-i <atlas_image2> -l <atlas_label2> -w <warped_image2> -a <warped_label2>
	...
	-i <atlas_imageN> -l <atlas_labelN> -w <warped_imageN> -a <warped_labelN>
ENDOFUSAGE
}



function report_parameters(){
# report parameters
	echo "number of atlases: ${#ATLAS_IMAGES[@]}"
	echo "prediction       : ${PREDICTION}"
	echo "target           : ${TARGET}"
	echo "parallel jobs    : ${PARALLELJOBS}"
	echo "verbose level    : ${VERBOSE}"
	echo "number of fusion : ${FUSENUM}"
	echo "fusion method    : ${FUSIONMETHOD}"
	echo "skip if possible : ${SKIP}"
}


# mandatory arguments
ATLAS_IMAGES=() # i
ATLAS_LABELS=() # l
WARPED_IMAGES=() # w
WARPED_LABELS=() # a
TARGET='' # t
PREDICTION='' # p

# optional arguments
PARALLELJOBS='3' # j
VERBOSE=0 # v
FUSENUM='4' # n
FUSIONMETHOD='majorityvote' # f
SKIP='1' # s


# parse arguments
while getopts 't:p:i:l:j:n:v:f:s:d:hw:a:' OPT
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
    w)
      WARPED_IMAGES[${#WARPED_IMAGES[@]}]="$OPTARG"
      ;;
    a)
      WARPED_LABELS[${#WARPED_LABELS[@]}]="$OPTARG"
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
			SKIP="$OPTARG"
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
test "${#ATLAS_IMAGES[@]}" -eq "${#ATLAS_LABELS[@]}" && \
  test "${#ATLAS_IMAGES[@]}" -eq "${#WARPED_IMAGES[@]}" && \
  test "${#ATLAS_LABELS[@]}" -eq "${#WARPED_LABELS[@]}" || \
	{ echo "number of -i -l -w -a options don't match" >&2; exit 1; }
# TARGET=''
test -r "$TARGET" || \
	{ echo "target (-t) not set or not accessable" >&2; usage; exit 1; }
# PREDICTION='' 
test -n "$PREDICTION" || \
	{ echo "label prediction (-p) not set" >&2; usage; exit 1; }

# optional arguments
test "${PARALLELJOBS}" -gt 0 || \
	{ echo "parallel jobs (-j) should > 0" >&2; exit 1; }
test "${VERBOSE}" -ge 0 || \
	{ echo "verbose (-j) option should >= 0" >&2; exit 1; }
test "${FUSENUM}" -ge 2 && test "${FUSENUM}" -le "${#ATLAS_LABELS[@]}" || \
	{ echo "fusenum (-n) should >=2 and <= ${#ATLAS_LABELS[@]}" >&2; 
		exit 1; }
test "${FUSIONMETHOD}" = "majorityvote" || \
	test "${FUSIONMETHOD}" = "staple" || \
	{ echo "invalid -f ${FUSIONMETHOD}" >&2; exit 1; }
test "${SKIP}" -ge 0 || \
	{ echo "skip (-s) should >= 0" >&2; exit 1; }

test "${VERBOSE}" -ge 2 && report_parameters
test "${VERBOSE}" -ge 3 && \
	echo "atlas images (in order): ${ATLAS_IMAGES[@]}" && \
	echo "atlas labels (in order): ${ATLAS_LABELS[@]}"
test "${VERBOSE}" -ge 4 && set -x

# get dimensionality
DIM="$( ${FSLHD} ${TARGET} | fgrep -w 'dim0' | tr -s ' ' | cut -d' ' -f2 )"
test "${DIM}" -ge 2 && test "${DIM}" -le 3 || \
	{ echo "dimensionality not available" >&2 ; exit 1; }


# do registration
BASEPATH="$(dirname ${PREDICTION})/$(basename ${PREDICTION} | cut -d. -f1)"
PARALLELJOB_DOREG=''
PARALLELJOB_APPLYT=''
for (( i = 0; i < ${#ATLAS_IMAGES[@]}; i++ ))
do
	WARPED_IMAGE="${WARPED_IMAGES[$i]}"
	WARPED_LABEL="${WARPED_LABELS[$i]}"
	TRANSFORM="${BASEPATH}_transform_${i}_"
	ATLAS_IMAGE="${ATLAS_IMAGES[$i]}"
	ATLAS_LABEL="${ATLAS_LABELS[$i]}"
	PARALLELJOB_DOREG="${PARALLELJOB_DOREG} \
		$DOREG \
		-d '${DIM}' \
		-f '${TARGET}' \
		-l '${ATLAS_LABEL}' \
		-m '${ATLAS_IMAGE}' \
		-t '${TRANSFORM}' \
		-s '${WARPED_LABEL}' \
		-w '${WARPED_IMAGE}' \
		-k '${SKIP}' \
		\n"
done
SHOWBAR=''
test "${VERBOSE}" -ge 2 && \
	{ echo "...doing registration"; SHOWBAR='--bar'; }
test "${VERBOSE}" -ge 3 && echo -e "registration jobs \n ${PARALLELJOB_DOREG}"
# ignore non-empty line
# (which will also be considered as a command in parallel)
echo -e "$PARALLELJOB_DOREG" | 	grep -v '^$' | \
	parallel --halt now,fail=1 -j $PARALLELJOBS $SHOWBAR || \
	{ echo "failed to registration in one or more jobs" >&2; exit 1; }


# label fusion
test "${VERBOSE}" -ge 2 && echo "...Measuring and Selecting labels"
# choose best n labels
# compute and sort similarity
# to be parallelized soon... (use seperate/one txt file to store result?)
SIMILARITIES=()
SIMILARITY_GATE=''
PARALLELJOB_SORT=''
# compute
for (( i = 0; i < ${#ATLAS_IMAGES[@]}; i++ ))
do
	# 1 for cross correlation
# Metric
# 0 - MeanSquareDifference
# 1 - Cross-Correlation # fgrep => CC
# 2-Mutual Information # fgrep => MI
# 3-SMI 
	SIMILARITY=$( MeasureImageSimilarity ${DIM} 2 \
		${TARGET} ${WARPED_IMAGES[$i]} | \
		fgrep '=> MI' | rev | cut -d' ' -f1 | rev )
	SIMILARITIES[${#SIMILARITIES[@]}]="${SIMILARITY}"
done
# sort
SIMILARITY_GATE=$( echo ${SIMILARITIES[@]} | \
	tr " " "\n" | sort -g | cut -d$'\n' -f"${FUSENUM}" )

test "$VERBOSE" -ge 1 && echo "similarity gatevalue: ${SIMILARITY_GATE}"
test "$VERBOSE" -ge 1 && echo "selected atlases and similarities:"
LABELS_CHOSEN=() # sometimes number of chosen labels may be larger than FUSENUM
for (( i = 0; i < ${#ATLAS_IMAGES[@]}; i++ ))
do
	test $(echo "${SIMILARITIES[${i}]} <= ${SIMILARITY_GATE}" | bc) \
	       	-eq 1 && \
		LABELS_CHOSEN[${#LABELS_CHOSEN[@]}]="${WARPED_LABELS[$i]}" && \
		test "$VERBOSE" -ge 1 && \
			echo "${i}: ${WARPED_IMAGES[$i]} : ${SIMILARITIES[$i]}"
done

# fuse
function majorityvote(){
	ImageMath "${DIM}" "${PREDICTION}" \
		MajorityVoting ${LABELS_CHOSEN[@]} || \
		{ echo "failed to do majority voting" >&2; exit 1; }
	}
function staple(){
	LABEL4D="${BASEPATH}_${FUSENUM}fuse_4D.nii.gz"
	fsl5.0-fslmerge -t ${LABEL4D} ${LABELS_CHOSEN[@]} || \
		{ echo "failed to merge to 4D label" >&2; exit 1; }
	seg_LabFusion -in "${LABEL4D}" -STAPLE -out "${PREDICTION}" || \
		{ echo "failed to do staple" >&2; exit 1; }
	}

case "$FUSIONMETHOD" in
	staple)
		staple
		;;
	majorityvote)
		majorityvote
		;;
	\?)
		echo "unknown fusion method" >&2
		exit 1
		;;
esac

exit 0

