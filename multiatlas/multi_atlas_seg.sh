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
  [-c atlas chosen method, default 2.
    0:MeanSquareDifference, 1:Cross-Correlation, 2:Mutual Information]
  [-s skip if possible( according to file modification date), default 0]
  [-o use affine registration only, default 0]
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
CHOSENMETHOD='2' # c
SKIP='1' # s
AFFINEONLY='0'

# atlas choose metric
CHOSENMETHODNAMES=("MSQ" "CC" "MI")

# parse arguments
while getopts 'a:c:d:f:hi:j:l:n:o:p:s:t:v:w:' OPT
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
    c) # altas chosen method
      CHOSENMETHOD="$OPTARG"
      ;;
    o) # affine registration only
      AFFINEONLY="$OPTARG"
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
test "${CHOSENMETHOD}" -ge 0 && test "${CHOSENMETHOD}" -le "2" || \
  { echo "choose method (-c) should be 0 or 1 or 2" >&2; exit 1; }
test "${PARALLELJOBS}" -gt 0 || \
  { echo "parallel jobs (-j) should > 0" >&2; exit 1; }
test "${VERBOSE}" -ge 0 || \
  { echo "verbose (-j) option should >= 0" >&2; exit 1; }
test "${FUSENUM}" -ge 1 && test "${FUSENUM}" -le "${#ATLAS_LABELS[@]}" || \
  { echo "fusenum (-n) should >=1 and <= ${#ATLAS_LABELS[@]}" >&2; 
    exit 1; }
test "${FUSIONMETHOD}" = "majorityvote" || \
  test "${FUSIONMETHOD}" = "staple" || \
  { echo "invalid -f ${FUSIONMETHOD}" >&2; exit 1; }
test "${SKIP}" -ge 0 || \
  { echo "skip (-s) should >= 0" >&2; exit 1; }
test "${AFFINEONLY}" -ge 0 ||\
  { echo "-o affine only should >=0" >&2; exit 1; }

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
  TRANSFORM="${WARPED_IMAGE}-transform"
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
    -a '${AFFINEONLY}' \
    \n"
done
SHOWBAR=''
test "${VERBOSE}" -ge 2 && \
  { echo "...doing registration"; SHOWBAR='--bar'; }
test "${VERBOSE}" -ge 3 && echo -e "registration jobs \n ${PARALLELJOB_DOREG}"
# ignore non-empty line
# (which will also be considered as a command in parallel)
echo -e "$PARALLELJOB_DOREG" |  grep -v '^$' | \
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
CHOSENMETHODNAME="${CHOSENMETHODNAMES[${CHOSENMETHOD}]}"
for (( i = 0; i < ${#ATLAS_IMAGES[@]}; i++ ))
do
  SIMILARITYFILE="${WARPED_IMAGES[$i]}.similarity"
  if test "${SKIP}" -gt "0" && \
    test -r "${SIMILARITYFILE}" && \
    test "${SIMILARITYFILE}" -nt "${WARPED_IMAGES[$i]}" && \
    fgrep -q "${CHOSENMETHODNAME}"':' "${SIMILARITYFILE}"
  then
    SIMILARITY=$(cat "${SIMILARITYFILE}" | grep "${CHOSENMETHODNAME}:" | \
      cut -d':' -f2)
    test -z "${SIMILARITY}" && \
      { echo "file ${SIMILARITYFILE} without ${CHOSENMETHODNAME} data" >&2 ; \
        exit 1; }
  else
# Metric
# 0-MeanSquareDifference # fgrep => MSQ
# 1-Cross-Correlation # fgrep => CC
# 2-Mutual Information # fgrep => MI
# 3-SMI # segmentation fault
    SIMILARITY=$( MeasureImageSimilarity "${DIM}" "${CHOSENMETHOD}" \
        "${TARGET}" "${WARPED_IMAGES[$i]}" | \
        fgrep '=> '"${CHOSENMETHODNAME}" | rev | cut -d' ' -f1 | rev )
    test -z "${SIMILARITY}" && \
        { echo "failed to measure similarity" >&2 ; exit 1; }
    test -e "${SIMILARITYFILE}" && \
        test "${SIMILARITYFILE}" -ot "${WARPED_IMAGES[$i]}" && \
        rm -rf "${SIMILARITYFILE}"
    test -e "${SIMILARITYFILE}" && \
        fgrep -v '=> '"${CHOSENMETHODNAME}" "${SIMILARITYFILE}" | \
          sponge "${SIMILARITYFILE}" 
    echo "${CHOSENMETHODNAME}:${SIMILARITY}" >>"${SIMILARITYFILE}"
  fi
  SIMILARITIES[$i]="${SIMILARITY}"
done
# sort
if test "${CHOSENMETHOD}" -eq 2
then
  SIMILARITY_GATE=$( echo "${SIMILARITIES[@]}" | \
    tr " " "\n" | sort -g | cut -d$'\n' -f"${FUSENUM}" )
else
  SIMILARITY_GATE=$( echo ${SIMILARITIES[@]} | \
    tr " " "\n" | sort -g -r | cut -d$'\n' -f"${FUSENUM}" )
fi

test "$VERBOSE" -ge 1 && echo "similarity gatevalue: ${SIMILARITY_GATE}"
test "$VERBOSE" -ge 1 && echo "selected atlases and similarities:"
LABELS_CHOSEN=() # sometimes number of chosen labels may be larger than FUSENUM
for (( i = 0; i < ${#ATLAS_IMAGES[@]}; i++ ))
do
  if test "${CHOSENMETHOD}" -eq 2
  then
    _COMPARESYM='<='
  else
    _COMPARESYM='>='
  fi
  test $(echo "${SIMILARITIES[${i}]} ${_COMPARESYM} ${SIMILARITY_GATE}" | bc) \
          -eq 1 && \
    LABELS_CHOSEN[${#LABELS_CHOSEN[@]}]="${WARPED_LABELS[$i]}" && \
    test "$VERBOSE" -ge 1 && \
      echo "${WARPED_LABELS[$i]} : ${ATLAS_IMAGES[$i]} :\
 ${SIMILARITIES[$i]} : ${ATLAS_LABELS[$i]} : $i"
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

