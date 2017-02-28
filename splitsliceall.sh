#!/bin/bash

PARALLEL_JOBS=4

function doit(){
	LSDATA=$(echo ${DIRIN}/*.nii.gz)
	DATA=''
	DATA_BASENAME=''
	for DATAIUM in $LSDATA
	do
		DATA="${DATA} ${DATAIUM}"
		DATAIUM=$(basename ${DIRIN}/${DATAIUM} .nii.gz)
		DATA_BASENAME="${DATA_BASENAME} ${DIROUT}/${DATAIUM}${SUFFIX}"
	done
	PICMD="parallel -j $PARALLEL_JOBS  --bar --link $CMD ::: $DATA ::: $DATA_BASENAME"
	echo $PICMD
	$PICMD
}

CMD='fsl5.0-fslsplit'
DIRIN='./data'
DIROUT='./splitteddata'
SUFFIX='_volume_'
doit

DIRIN='./gt'
DIROUT='./splittedgt'
doit

CMD='fsl5.0-fslslice'
DIRIN='./splitteddata'
DIROUT='./sliceddata'
SUFFIX=''
doit

DIRIN='./splittedgt'
DIROUT='./slicedgt'
doit

exit 0
