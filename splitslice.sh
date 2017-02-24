#!/bin/bash
function showusage {
	cat << ENDUSAGE

Split (4D->3D) then slice (3D->2D) 4D images.

Usage:
$0 -i InputFile/Dir -p Outputprefix -o OutputDir

if OutputDir not specified, OutputDir is the same as InputDir.

ENDUSAGE
	exit 1
}

FSLSPLIT='fsl5.0-fslsplit'
FSLSLICE='fsl5.0-fslslice'
INPUTDIR=''
OUTPUTPREFIX=''
OUTPUTDIR=''

# check if needed commands exit
type "$FSLSPLIT"  >/dev/null 2>&1 || \
	echo "Error! Cannot find a command named $FSLSPLIT" || \
	exit 1
type "$FSLSLICE" >/dev/null 2>&1 || \
	echo "Error! Cannot find a command named $FSLSLICE" || \
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
done


exit 0
