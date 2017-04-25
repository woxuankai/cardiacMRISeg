#!/bin/bash

function usage(){
	cat >&2 << EOF
An interface to easily invoke multi_atlas_seg.sh

Usage:
$0 -d <digit, d?> -v <digit, v?> -s <digit, s?> -n <digit, n labels to fuse>
	[-j <digit, parallel jobs>] [-m <verbose level, more information>]
	[-f <fusion method>]
	[-h <,help>]

AUTHOR: Kai Xuan <woxuankai@gmail.com>
EOF
}

JOBS='1'
VERBOSE='0'
FUSIONMETHOD='staple'
while getopts 'd:s:v:n:j:m:f:h' OPT
do
	case $OPT in
		d)
			SPEC="$OPTARG"
			;;
		v)
			VOL="${OPTARG}"
			;;
		s)
			SLICE="${OPTARG}"
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
		f)
			FUSIONMETHOD="${OPTARG}"
			;;
		h)
			usage
			;;
		\?)
			usage
			;;
	esac
done

test "$SPEC"  || \
	{ echo "wrong -d or/and -v set" >&2 ; usage  ; exit 1; }
SPEC="d${SPEC}"
VOL="v${VOL}"
SLICE="s${SLICE}"
test "$LN" -ge 1 || \
	{ echo "-n should >= 1" >&2 ; usage ; exit 1; }
test "${VERBOSE}" -ge 0 || \
	{ echo "-v should >=0" >&2 ; usage ; exit 1; }


TARGET="${SPEC}"
test "${#VOL}" -ge 1 && TARGET="${TARGET}_${VOL}" && \
test "${#SLICE}" -ge 1 && TARGET="${TARGET}_${SLICE}"

PREDICTION="./output/${TARGET}_seg_prediction.nii.gz"
test "$VERBOSE" -ge 1 &&  echo "target ${TARGET}"

ATLAS=$(ls ./data | fgrep -v ${SPEC} | fgrep -v seg)
ARG=''
for ONEATLAS in $ATLAS
do
	BASENAME=$(echo "$ONEATLAS" | cut -d'.' -f1)
	ARG="${ARG} \
-i ./data/${BASENAME}.nii.gz -l ./data/${BASENAME}_seg.nii.gz \
-w ./output/${TARGET}-${BASENAME}-warpedimage.nii.gz \
-a ./output/${TARGET}-${BASENAME}-warpedlabel.nii.gz"
done

test "$VERBOSE" -ge 3 && echo "altases argument ${ARG}"

function dodice(){ # 1-> prediction 2->target  (file path)
	LabelOverlapMeasures 2 "${1}" "${2}" | \
		cut -d$'\n' -f6 | tr -s ' ' | \
		cut -d' ' -f5 | echo -n "dice:$( cat - )" || \
		{ echo "failed to measure dice" >&2; exit 1; }
	return 0
	}


DOMAS='./multi_atlas_seg.sh \
	-t "./data/${TARGET}.nii.gz" \
	-p "${PREDICTION}" \
	-v "${VERBOSE}" \
	-j "${JOBS}" \
	-n "${LN}" \
	-f "${FUSIONMETHOD}" \
	${ARG}'

if test "${VERBOSE}" -eq 1
then
	set -o pipefail
	eval "${DOMAS}" | fgrep ".nii.gz" | tr ':' ' ' | \
		{ while read ONESEG ONEIMG ONESIM; \
		do dodice "${ONESEG}" "data/${TARGET}_seg.nii.gz"; \
			echo -e ":${ONEIMG}"; done }
	test "$?" -eq 0 || \
		{ echo "failed to do multi-atlas-segmentation and/or dice" >&2; exit 1; }
	set +o pipefail
else
	eval "${DOMAS}" || \
		{ echo "failed to do multi-atlas-segmentation" >&2; exit 1; }
fi

dodice "$PREDICTION" "./data/${TARGET}_seg.nii.gz"
echo -e ":$PREDICTION"

exit 0;
