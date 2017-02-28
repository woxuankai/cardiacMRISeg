#!/bin/bash

function usage(){
	cat <<ENDOFUSAGE
usage:
multi_atlas_seg.sh
	-t <target> -o <target_label_prediction>
	-i <atlas_img1> -l <atlas_label1>
	-i <atlas_img2> -l <atlas_label2>
	...
	-i <atlas_imgN> -l <atlas_labelN>
ENDOFUSAGE
}

