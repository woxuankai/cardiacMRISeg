#!/bin/bash
# csv sample output
# target,atlas_img,dice,MSQ,CC,MI #,MS_affine,CC_affine,MI_affine

function usage(){
  cat >&2 << EOF
usage:

$0 target
for example  ./gen_csv.sh d0_v2_s1
EOF
}

test $# -ne 1 && { usage; exit 1; }
TARGET="$1"

echo "target,atlas_img,dice,MSQ,CC,MI"

for ONESEG in $(ls output | egrep "${TARGET}"'-[0-Z_]*-warpedlabel\.nii\.gz')
do
  DICE=$(LabelOverlapMeasures 2 \
      "data/${TARGET}_seg.nii.gz" "output/${ONESEG}" | \
      cut -d$'\n' -f6 | tr -s ' ' | cut -d' ' -f5)
  ATLAS=$(echo ${ONESEG} | cut -d'-' -f 2)
  MI=$( MeasureImageSimilarity 2 2 \
      "data/${TARGET}.nii.gz" "output/${TARGET}-${ATLAS}-warpedimage.nii.gz" |\
      fgrep '=> MI' | rev | cut -d' ' -f1 | rev )
  CC=$( MeasureImageSimilarity 2 1 \
      "data/${TARGET}.nii.gz" "output/${TARGET}-${ATLAS}-warpedimage.nii.gz" |\
      fgrep '=> CC' | rev | cut -d' ' -f1 | rev )
  MSQ=$( MeasureImageSimilarity 2 0 \
      "data/${TARGET}.nii.gz" "output/${TARGET}-${ATLAS}-warpedimage.nii.gz" |\
      fgrep '=> MSQ' | rev | cut -d' ' -f1 | rev )
  echo "data/${TARGET}.nii.gz,data/${ATLAS}.nii.gz,${DICE},${MSQ},${CC},${MI}"
done

