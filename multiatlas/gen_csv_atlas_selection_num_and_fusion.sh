#!/bin/bash

function usage(){
  cat >&2 << EOF
usage:

$0 target
for example  ./gen_csv.sh d0_v2_s1
EOF
}

test $# -ne 1 && { usage; exit 1; }
TARGET="$1"

echo "target,num,MV,STAPLE"

for NUM in $(seq 1 20)
do
  D=$(echo ${TARGET} | cut -d'_' -f 1)
  V=$(echo ${TARGET} | cut -d'_' -f 2)
  S=$(echo ${TARGET} | cut -d'_' -f 3)
  ARGRUN="-$D -$V -$S -m1"
  DICESTAPLE=$(./run.sh ${ARGRUN} -n ${NUM} -f staple |\
    fgrep prediction | cut -d':' -f2)
  DICEMV=$(./run.sh ${ARGRUN} -n ${NUM} -f majorityvote |\
    fgrep prediction | cut -d':' -f2)
  echo "data/${TARGET}.nii.gz,${NUM},${DICEMV},${DICESTAPLE}"
done

