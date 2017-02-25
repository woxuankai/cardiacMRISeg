#!/bin/bash

# filename splitslice.sh
# auther: Kai Xuan (woxuankai@gmail.com)

function showusage (){
	cat << ENDUSAGE

Split (4D->3D) then slice (3D->2D) 4D images.

Usage:
splitslice.sh -i InputFile [-o OutputBase]

Note:

If  is the same as InputDir.

ENDUSAGE
	exit 1
}

function splitslice(){
	# fsl5.0-fslspllit will add only xxxx to distinguish different volumes
	# fsl5.0-fslslice will add _slice_xxxx to distinguish different slices
	# thus add _volume_ to match fslslice style
	$SPLIT "${1}" "${2}_volume_" -t
	SPLITS=$(ls ${2}_volume_*)
	for ONESPLIT in $SPLITS
	do
		$SLICE "$ONESLPIT"

SPLIT='fsl5.0-fslsplit'
SLICE='fsl5.0-fslslice'
INPUTDIR=''
OUTPUTPREFIX=''
OUTPUTDIR=''

# check if needed commands exit
type "$SPLIT"  >/dev/null 2>&1 || \
	echo "Error! Cannot find a command named $SPLIT" || \
	exit 1
type "$SLICE" >/dev/null 2>&1 || \
	echo "Error! Cannot find a command named $SLICE" || \
	exit 1

# reading command line arguments
while getopts "p:o:i:" OPT
do
	case $OPT in
		i)
			INPUTDIR="$OPTARG"
			;;
		o)
			OUTPUTDIR="$OPTARG"
			;;
		d)
			OUTPUTPREFIX="$OPTARG"
			;;
	esac
done

#check arguments
if test -z "$INPUTDIR"
then
	echo "Error! input (-i) not specified!"
	showusage
	exit 1
fi
if test -z "$OUTPUTDIR"
then
	if test -d "$INPUTDIR"
	then
		OUTPUTDIR="$INPUTDIR"
	elif test -f "$INPUTDIR"
	then
		OUTPUTDIR="$(dirname $INPUTDIR)"
	else
		echo "Error! InputDir/File (-i)  is neither a directory \
			no a regular file"
		exit 1
	fi
fi

# split and slice
# both file and directory works fine with ls
for INPUTFILE in $(ls $INPUTDIR)
do
	echo "processing $INPUTFILE ..."
	splitslice "$INPUTFILE" "$OUTPUTDIR//$OUTPUTPREFIX"
done


exit 0
