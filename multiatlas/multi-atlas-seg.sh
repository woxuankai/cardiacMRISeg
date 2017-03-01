#!/bin/bash

function usage(){
	cat <<ENDOFUSAGE
usage:
multi_atlas_seg.sh
	-t <target> -p <target_label_prediction>
	-i <atlas_img1> -l <atlas_label1>
	-i <atlas_img2> -l <atlas_label2>
	...
	-i <atlas_imgN> -l <atlas_labelN>
ENDOFUSAGE
}

#doreg.sh -f <fixed image (target)> -l <label of moving image (atlas seg)>
#-m <moving image (atlas lable)> -t <transform basename>
#-s <warped label (target seg)> -w <warped image>

