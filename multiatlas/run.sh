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

JOBS='4'
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


#SPEC="d${SPEC}"
#VOL="v${VOL}"
#SLICE="s${SLICE}"
test "$LN" -ge 1 || \
	{ echo "-n should >= 1" >&2 ; usage ; exit 1; }
test "${VERBOSE}" -ge 0 || \
	{ echo "-v should >=0" >&2 ; usage ; exit 1; }


test "${SPEC}" -ge 0 && TARGET="d${SPEC}" && \
test "${VOL}" -ge 0 && TARGET="${TARGET}_v${VOL}" && \
test "${SLICE}" -ge 0 && TARGET="${TARGET}_s${SLICE}" || \
	{ echo "wrong -d or/and -v or/and -s set" >&2 ; usage  ; exit 1; }

PREDICTION="./output/${TARGET}_seg_${LN}_${FUSIONMETHOD}_prediction.nii.gz"
test "$VERBOSE" -ge 1 &&  echo "target ${TARGET}"

INFOFILE="./data/d${SPEC}.info"
test -r "${INFOFILE}" || { echo "cannot find ${INFOFILE}" 1>&2; exit 1; }
TARGET_NUM_SLICE=$(fgrep 'NUM_SLICE' ${INFOFILE} | cut -d'=' -f2)
test -n "${TARGET_NUM_SLICE}" || \
  { echo "cannot find NUM_VOLUME in ${INFOFILE}" 1>&2; exit 1; }

INFOFILES=$(ls ./data/ | egrep '\.info$' | egrep -v '^'"d${SPEC}\.info" )
unset BASENAMES
for ONEINFOFILE in ${INFOFILES}
do
  ATLAS_NUM_SLICE=$(fgrep 'NUM_SLICE' data/${ONEINFOFILE} | cut -d'=' -f2)
  ATLAS_NUM_VOLUME=$(fgrep 'NUM_VOLUME' data/${ONEINFOFILE} | cut -d'=' -f2)
  test -n "${ATLAS_NUM_SLICE}" && test -n "${ATLAS_NUM_VOLUME}" || \
    { echo "cannot find NUM_VOLUME/SLICE in ${ONEINFOFILE}" 1>&2; exit 1; }
  ATLAS_SPEC=$(echo ${ONEINFOFILE} | cut -d'.' -f 1)
  for ONESLICE in $(seq 0 $((${ATLAS_NUM_SLICE} - 1)))
  do
    NUM_SLICE="${TARGET_NUM_SLICE}"
    # requirement
    # abs((SLICE / NUM_SLICE * ATLAS_NUM_SLICE ) - ONESLICE) < 2
    # //then there will be 3 or 4 atlases selected
    # <=> NUM_SLICE*(ONESLICE-2) < SLICE*NUM_SLICE &&
    #     SLICE*NUM_SLICE < NUM_SLICE*(ONESLICE+2)
    # echo $((${NUM_SLICE}*(${ONESLICE}-2))) $((${SLICE}*${ATLAS_NUM_SLICE})) $((${NUM_SLICE}*(${ONESLICE}+2)))
    MARGIN=2
    if test 0 -eq \
      $((${NUM_SLICE}*(${ONESLICE}-${MARGIN})<${SLICE}*${ATLAS_NUM_SLICE})) ||\
      test 0 -eq \
      $((${NUM_SLICE}*(${ONESLICE}+${MARGIN}) > ${SLICE}*${ATLAS_NUM_SLICE}))
    then
      continue
    fi
    for ONEVOLUME in $(seq 0 $((${ATLAS_NUM_VOLUME} - 1)))
    do
      # continue if ONEVOLUME is odd
      if test 0 -eq $((${ONEVOLUME} == ${ONEVOLUME}/2*2))
      then
        continue
      fi
      BASENAMES[${#BASENAMES[@]}]="${ATLAS_SPEC}_v${ONEVOLUME}_s${ONESLICE}"
    done
  done
done
  

#echo "${BASENAMES[@]}" 1>&2

#ATLASES=$(ls ./data | fgrep -v "s${SPEC}" | fgrep -v seg)
unset ARG
for BASENAME in ${BASENAMES[@]}
do
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
