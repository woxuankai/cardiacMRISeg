#!/bin/bash

function usage(){
	cat >&2 << EOF
$0 -d <digit, d?> -v <digit, v?> -n <digit, n labels to fuse>
	[-j <digit, parallel jobs>] [-m <verbose level, more information>]
	[-h <,help>]

AUTHOR: Kai Xuan <woxuankai@gmail.com>
EOF
}

JOBS='1'
VERBOSE='0'
while getopts 'd:s:v:n:j:m:h' OPT
do
	case $OPT in
		d)
			SPEC="$OPTARG"
			;;
		s) # reserved for slice
			;;
		v)
			VOL="${OPTARG}"
			;;
		n)
			LN="${OPTARG}"
			;;
		j)
			JOBS="${OPTARG}"
			;;
		m)
			VERBOSE="${OPTARG}";
			;;
		h)
			usage
			;;
		\?)
			usage
			;;
	esac
done

test "$SPEC" -ge 0 && test "${VOL}" -ge 0 || \
	{ echo "wrong -d or/and -v set" >&2 ; exit 1; }
SPEC="d${SPEC}"
VOL="v${VOL}"
test "$LN" -ge 2 || \
	{ echo "-n should >= 2" >&2 ; exit 1; }
test "${VERBOSE}" -ge 0 || \
	{ echo "-v should >=0" >&2 ; exit 1; }


TARGET="${SPEC}_${VOL}"
PREDICTION="./output/${TARGET}_seg_prediction.nii.gz"
test "$VERBOSE" -ge 1 &&  echo "target ${TARGET}"

ATLAS=$(ls ./data | fgrep -v ${SPEC} | fgrep -v seg)
ARG=''
for ONEATLAS in $ATLAS
do
	BASENAME=$(echo "$ONEATLAS" | cut -d'.' -f1)
	ARG="${ARG} \
-i ./data/${BASENAME}.nii.gz -l ./data/${BASENAME}_seg.nii.gz"
done

test "$VERBOSE" -ge 3 && echo "altases argument ${ARG}"

./multi_atlas_seg.sh \
	-t "./data/${TARGET}.nii.gz" \
	-p "${PREDICTION}" \
	-v "${VERBOSE}" \
	-j "${JOBS}" \
	-n "${LN}" \
	${ARG} || \
	{ echo "failed to do multi-atlas-segmentation" >&2; exit 1; }

LabelOverlapMeasures 2 "${PREDICTION}" "./data/${TARGET}_seg.nii.gz" | \
	cut -d$'\n' -f6 | tr -s ' ' | \
	cut -d' ' -f5 | echo "dice: $( cat - )" || \
	{ echo "failed to measure dice" >&2; exit 1; }

exit 0;
